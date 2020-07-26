defmodule Imagism.Plug do
  import Plug.Conn

  def init(adapter) do
    adapter
  end

  def process(conn, image, params) do
    content_type = Imagism.Image.content_type(image)

    steps = [
      fn image ->
        {w, h} = Imagism.Image.dimensions(image)
        fallback_w = if params.h != nil, do: Kernel.round(params.h * w / h), else: w
        fallback_h = if params.w != nil, do: Kernel.round(params.w * h / w), else: h

        {
          :ok,
          if params.w != nil or params.h != nil do
            Imagism.Image.resize_exact(image, params.w || fallback_w, params.h || fallback_h)
          else
            image
          end
        }
      end,
      fn image ->
        {:ok,
         if(params.brighten != nil,
           do: Imagism.Image.brighten(image, params.brighten),
           else: image
         )}
      end,
      fn image ->
        {:ok, if(params.blur != nil, do: Imagism.Image.blur(image, params.blur), else: image)}
      end,
      fn image ->
        Imagism.Image.encode(image)
      end
    ]

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

  def call(conn, adapter) do
    case Imagism.Adapter.open(adapter, conn.request_path) do
      {:ok, image} ->
        Imagism.Plug.process(
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
end
