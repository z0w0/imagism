defmodule Imagism do
  use Application
  require Logger

  @doc """
  Starts the Imagism server.
  Any configuration errors will raise an error
  prior to the server starting.
  """
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Imagism.Supervisor]

    adapter =
      case Application.fetch_env!(:imagism, :adapter) do
        "file" ->
          Imagism.Adapter.new_file(Application.fetch_env!(:imagism, :file_path))

        "s3" ->
          Imagism.Adapter.new_s3(
            Application.fetch_env!(:imagism, :s3_bucket),
            Application.fetch_env!(:imagism, :s3_region) || "us-east-1"
          )

        nil ->
          raise "no adapter set"

        _ ->
          raise "unknown adapter"
      end

    port = Application.fetch_env!(:imagism, :port)

    children = [
      {Plug.Cowboy, scheme: :http, plug: {Imagism.Plug, adapter}, options: [port: port]}
    ]

    Logger.info("Listening on port #{port}")
    Supervisor.start_link(children, opts)
  end
end
