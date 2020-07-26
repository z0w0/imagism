defmodule Imagism do
  use Application

  @doc """
  Starts the Imagism server.
  Any configuration errors will raise an error
  prior to the server starting.
  """
  def start(_type, _args) do
    unless Mix.env() == :prod do
      Envy.auto_load()
    end

    opts = [strategy: :one_for_one, name: Imagism.Supervisor]

    adapter =
      case Application.fetch_env!(:imagism, :adapter) do
        "file" -> Imagism.Adapter.new_file(Application.fetch_env!(:imagism, :file_path))
        nil -> raise "no adapter set"
        _ -> raise "unknown adapter"
      end

    children = [
      {Plug.Cowboy, scheme: :http, plug: {Imagism.Plug, adapter}, options: [port: 8000]}
    ]

    Supervisor.start_link(children, opts)
  end
end
