defmodule Imagism.Adapter do
  @moduledoc """
  An adapter handles loading images from a configured
  source.
  """
  @type t() :: %Imagism.Adapter{}

  defstruct type: nil, file_path: nil

  @doc """
  Creates a new file adapter that loads images from the directory `path`.
  """
  @spec new_file(binary) :: Imagism.Adapter.t()
  def new_file(path) when is_binary(path) do
    %Imagism.Adapter{
      type: :file,
      file_path: Path.expand(path, File.cwd!())
    }
  end

  @doc """
  Opens an image by `path` using the provided `adapter`.
  """
  @spec open(Imagism.Adapter.t(), binary) :: {:ok, Imagism.Image.t()} | {:error, any}
  def open(adapter, path) do
    case adapter.type do
      :file -> Imagism.Image.open(Path.join(adapter.file_path, path))
    end
  end
end
