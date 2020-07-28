defmodule Imagism.Image do
  @moduledoc """
  A loaded image that can be processed and encoded.
  """
  @type t() :: %Imagism.Image{}

  defstruct resource: nil,
            reference: nil

  @doc """
  Wraps an image returned from the NIF with a reference.
  """
  @spec wrap_resource(any) :: Imagism.Image.t()
  def wrap_resource(resource) do
    %__MODULE__{
      resource: resource,
      reference: make_ref()
    }
  end

  @doc """
  Opens an image at a specific file `path`.
  """
  @spec open(binary) :: {:error, any} | {:ok, Imagism.Image.t()}
  def open(path) when is_binary(path) do
    case Imagism.Native.open(path) do
      {:ok, res} -> {:ok, Imagism.Image.wrap_resource(res)}
      err -> err
    end
  end

  @doc """
  Decodes an image from `bits`. It will guess the image's file format
  or default to JPEG.
  """
  @spec decode(bitstring()) :: {:error, any} | {:ok, Imagism.Image.t()}
  def decode(bits) when is_bitstring(bits) do
    case Imagism.Native.decode(bits) do
      {:ok, res} -> {:ok, Imagism.Image.wrap_resource(res)}
      err -> err
    end
  end

  @doc """
  Returns the MIME type of an `image`.
  """
  @spec content_type(Imagism.Image.t()) :: String.t()
  def content_type(image) do
    Imagism.Native.content_type(image.resource)
  end

  @doc """
  Returns the dimensions of an `image`.
  """
  @spec dimensions(Imagism.Image.t()) :: {integer(), integer()}
  def dimensions(image) do
    Imagism.Native.dimensions(image.resource)
  end

  @doc """
  Encodes an `image` to a binary or returns an error explaining
  what went wrong.
  """
  @spec encode(Imagism.Image.t()) :: {:err, any} | {:ok, binary}
  def encode(image) do
    Imagism.Native.encode(image.resource)
  end

  @doc """
  Brightens an `image` by a multiplier `value`.
  If the value is negative, the image will be darkened instead.
  """
  @spec brighten(Imagism.Image.t(), integer) :: Imagism.Image.t()
  def brighten(image, value) when is_integer(value) do
    Imagism.Image.wrap_resource(Imagism.Native.brighten(image.resource, value))
  end

  @doc """
  Adjusts the contrast of `image` by a constant `value`.
  If the value is negative, the contrast will be decreased.
  """
  @spec contrast(Imagism.Image.t(), float) :: Imagism.Image.t()
  def contrast(image, value) when is_float(value) do
    Imagism.Image.wrap_resource(Imagism.Native.contrast(image.resource, value))
  end

  @doc """
  Blur an `image` by `sigma`.
  The larger the `sigma`, the longer this operation will take.
  """
  @spec blur(Imagism.Image.t(), float) :: Imagism.Image.t()
  def blur(image, sigma) when is_float(sigma) do
    Imagism.Image.wrap_resource(Imagism.Native.blur(image.resource, sigma))
  end

  @doc """
  Flips an `image` vertically.
  """
  @spec flipv(Imagism.Image.t()) :: Imagism.Image.t()
  def flipv(image) do
    Imagism.Image.wrap_resource(Imagism.Native.flipv(image.resource))
  end

  @doc """
  Flips an `image` horizontally.
  """
  @spec fliph(Imagism.Image.t()) :: Imagism.Image.t()
  def fliph(image) do
    Imagism.Image.wrap_resource(Imagism.Native.fliph(image.resource))
  end

  @doc """
  Resize an `image` to an exact `{w, h}` dimension.
  """
  @spec resize(Imagism.Image.t(), integer, integer) :: Imagism.Image.t()
  def resize(image, w, h) when is_integer(w) and is_integer(h) do
    Imagism.Image.wrap_resource(Imagism.Native.resize(image.resource, w, h))
  end

  @doc """
  Crop an `image` at a position `{x, y}` to a specific `{w, h}`.
  """
  @spec crop(Imagism.Image.t(), integer, integer, integer, integer) :: Imagism.Image.t()
  def crop(image, x, y, w, h)
      when is_integer(x) and is_integer(y) and is_integer(w) and is_integer(h) do
    Imagism.Image.wrap_resource(Imagism.Native.crop(image.resource, x, y, w, h))
  end

  @doc """
  Rotates an `image` by an amount of `rotation` in degrees.
  Only a 90, 180 or 270 degree rotation is supported.
  Anything else won't change the image.
  """
  @spec rotate(Imagism.Image.t(), integer) :: Imagism.Image.t()
  def rotate(image, rotation) when is_integer(rotation) do
    Imagism.Image.wrap_resource(Imagism.Native.rotate(image.resource, rotation))
  end
end

defimpl Inspect, for: Imagism.Image do
  import Inspect.Algebra

  def inspect(dict, opts) do
    concat(["#Imagism.Image<", to_doc(dict.reference, opts), ">"])
  end
end
