defmodule Imagism.Plug do
  @moduledoc """
  The plug handles the HTTP requests.
  """
  import Plug.Conn
  use Plug.Builder

  plug(Plug.Logger)

  @doc """
  Initialises the plug using the provided `adapter`.
  """
  @spec init(Imagism.Adapter.t()) :: Imagism.Adapter.t()
  def init(adapter) do
    adapter
  end

  @doc """
  Processes `image` using the provided `params` and then
  responds to `conn`.
  """
  @spec process_image(Plug.Conn.t(), Imagism.Image.t(), Imagism.Params.t()) :: Plug.Conn.t()
  def process_image(conn, image, params) do
    Logger.metadata(Map.to_list(Map.from_struct(params)))

    content_type = Imagism.Image.content_type(image)

    steps = [
      # Handle ?w, ?h and ?fit
      fn image ->
        {w, h} = Imagism.Image.dimensions(image)
        aspect_w = if params.h != nil, do: Kernel.round(params.h * w / h), else: w
        aspect_h = if params.w != nil, do: Kernel.round(params.w * h / w), else: h

        {
          :ok,
          if params.w != nil or params.h != nil do
            case params.resize do
              :crop ->
                {x_ratio, y_ratio} =
                  Enum.reduce(params.crop, {0.5, 0.5}, fn crop_opt, {x_ratio, y_ratio} ->
                    case crop_opt do
                      :top -> {x_ratio, 0}
                      :bottom -> {x_ratio, 1}
                      :left -> {0, y_ratio}
                      :right -> {1, y_ratio}
                      _ -> {x_ratio, y_ratio}
                    end
                  end)

                crop_w = params.w || aspect_w
                crop_h = params.h || aspect_h

                Imagism.Image.crop(
                  image,
                  Kernel.max(0, Kernel.min(w - crop_w, Kernel.round(x_ratio * w - crop_w / 2))),
                  Kernel.max(0, Kernel.min(h - crop_h, Kernel.round(y_ratio * h - crop_h / 2))),
                  crop_w,
                  crop_h
                )

              :exact ->
                Imagism.Image.resize(image, params.w || w, params.h || h)

              _ ->
                Imagism.Image.resize(image, params.w || aspect_w, params.h || aspect_h)
            end
          else
            image
          end
        }
      end,

      # Handle ?flip
      fn image ->
        {
          :ok,
          case params.flip do
            :h -> Imagism.Image.fliph(image)
            :v -> Imagism.Image.flipv(image)
            :hv -> Imagism.Image.fliph(Imagism.Image.flipv(image))
            _ -> image
          end
        }
      end,

      # Handle ?rotate
      fn image ->
        {
          :ok,
          if(params.rotate != nil, do: Imagism.Image.rotate(image, params.rotate), else: image)
        }
      end,

      # Handle ?brighten
      fn image ->
        {:ok,
         if(params.brighten != nil,
           do: Imagism.Image.brighten(image, params.brighten),
           else: image
         )}
      end,

      # Handle ?contrast
      fn image ->
        {:ok,
         if(params.contrast != nil,
           do: Imagism.Image.contrast(image, params.contrast),
           else: image
         )}
      end,

      # Handle ?blur
      fn image ->
        {:ok, if(params.blur != nil, do: Imagism.Image.blur(image, params.blur), else: image)}
      end,

      # Output the final processed binary
      fn image ->
        Imagism.Image.encode(image)
      end
    ]

    # Produces the final processed image. Any error will ignore future steps.
    processed_image =
      Enum.reduce(
        steps,
        {:ok, image},
        fn
          step, {:ok, image} -> step.(image)
          _, err -> err
        end
      )

    case processed_image do
      {:ok, binary} ->
        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, binary)

      {:error, error} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(500, "Process error: #{error}")
    end
  end

  @doc """
  Handles a connection using the initialised `adapter`.
  The request path is passed onto the `adapter`, parses the
  query params into image processing parameters and then processes the image.
  """
  @spec open_image(Plug.Conn.t(), Imagism.Adapter.t()) :: Plug.Conn.t()
  def open_image(conn, adapter) do
    case Imagism.Adapter.open(adapter, conn.request_path) do
      {:ok, image} ->
        Imagism.Plug.process_image(
          conn,
          image,
          Imagism.Params.new(Plug.Conn.fetch_query_params(conn).query_params)
        )

      {:error, :enoent} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "Not found")

      {:error, error} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(500, "Adapter error: #{error}")
    end
  end

  @doc """
  Handles the connection `conn` and calls the other plugs.
  """
  @spec call(Plug.Conn.t(), Imagism.Adapter.t()) :: Plug.Conn.t()
  def call(conn, opts) do
    conn
    |> super(opts)
    |> assign(:called_all_plugs, true)
    |> open_image(opts)
  end
end
