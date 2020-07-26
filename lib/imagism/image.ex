defmodule Imagism.Image do
  @moduledoc """
  A loaded image that can be processed and encoded.
  """
  @type t() :: %Imagism.Image{}

  defstruct resource: nil,
            reference: nil

  def wrap_resource(resource) do
    %__MODULE__{
      resource: resource,
      reference: make_ref()
    }
  end

  def open(path) when is_binary(path) do
    case Imagism.Native.open(path) do
      {:error, err} -> {:error, err}
      {:ok, res} -> {:ok, Imagism.Image.wrap_resource(res)}
    end
  end

  def content_type(image) do
    Imagism.Native.content_type(image.resource)
  end

  def dimensions(image) do
    Imagism.Native.dimensions(image.resource)
  end

  def encode(image) do
    Imagism.Native.encode(image.resource)
  end

  def save(image, path) when is_binary(path) do
    Imagism.Native.save(image.resource, path)
  end

  def brighten(image, value) when is_integer(value) do
    Imagism.Image.wrap_resource(Imagism.Native.brighten(image.resource, value))
  end

  def blur(image, sigma) when is_float(sigma) do
    Imagism.Image.wrap_resource(Imagism.Native.blur(image.resource, sigma))
  end

  def resize(image, w, h) when is_integer(w) and is_integer(h) do
    Imagism.Image.wrap_resource(Imagism.Native.resize(image.resource, w, h))
  end

  def resize_exact(image, w, h) when is_integer(w) and is_integer(h) do
    Imagism.Image.wrap_resource(Imagism.Native.resize_exact(image.resource, w, h))
  end

  def crop(image, x, y, w, h)
      when is_integer(x) and is_integer(y) and is_integer(w) and is_integer(h) do
    Imagism.Image.wrap_resource(Imagism.Native.crop(image.resource, x, y, w, h))
  end
end

defimpl Inspect, for: Imagism.Image do
  import Inspect.Algebra

  def inspect(dict, opts) do
    concat(["#Imagism.Image<", to_doc(dict.reference, opts), ">"])
  end
end
