defmodule Imagism.Adapter do
  @moduledoc """
  An adapter handles loading images from a configured
  source.
  """
  @type t() :: %Imagism.Adapter{}

  defstruct type: nil, file_path: nil, s3_bucket: nil, s3_region: nil

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
  Creates a new S3 adapter that loads images from a `bucket` (in `region`).
  The credentials will be loaded from the standard AWS
  environment variables.
  """
  @spec new_s3(binary, binary) :: Imagism.Adapter.t()
  def new_s3(bucket, region) when is_binary(bucket) and is_binary(region) do
    %Imagism.Adapter{
      type: :s3,
      s3_bucket: bucket,
      s3_region: region
    }
  end

  @doc """
  Opens an image by `path` using the provided `adapter`.
  """
  @spec open(Imagism.Adapter.t(), binary) :: {:ok, Imagism.Image.t()} | {:error, any}
  def open(adapter, path) do
    case adapter.type do
      :file ->
        case File.read(Path.join(adapter.file_path, path)) do
          {:ok, file_data} ->
            Imagism.Image.decode(file_data)

          err ->
            err
        end

      :s3 ->
        res =
          ExAws.S3.get_object(adapter.s3_bucket, path)
          |> ExAws.request(region: adapter.s3_region)

        case res do
          {:ok, %{body: s3_data}} ->
            Imagism.Image.decode(s3_data)

          {:error, {:http_error, 404, _}} ->
            {:error, :enoent}

          err ->
            err
        end
    end
  end
end
