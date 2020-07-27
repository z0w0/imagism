defmodule Imagism.Native do
  @moduledoc """
  The native module that calls into the imagism crate via Rustler.
  """
  use Rustler, otp_app: :imagism, crate: :imagism

  defp error, do: :erlang.nif_error(:nif_not_loaded)

  @spec open(String.t()) :: {:ok, Imagism.Image.t()} | {:err, any}
  def open(_path), do: error()

  @spec brighten(Imagism.Image.t(), integer()) :: Imagism.Image.t()
  def brighten(_image, _value), do: error()

  @spec blur(Imagism.Image.t(), float()) :: Imagism.Image.t()
  def blur(_image, _sigma), do: error()

  @spec flipv(Imagism.Image.t()) :: Imagism.Image.t()
  def flipv(_image), do: error()

  @spec fliph(Imagism.Image.t()) :: Imagism.Image.t()
  def fliph(_image), do: error()

  @spec resize(Imagism.Image.t(), integer(), integer()) :: Imagism.Image.t()
  def resize(_image, _w, _h), do: error()

  @spec crop(Imagism.Image.t(), integer(), integer(), integer(), integer()) :: Imagism.Image.t()
  def crop(_image, _x, _y, _w, _h), do: error()

  @spec content_type(Imagism.Image.t()) :: String.t()
  def content_type(_image), do: error()

  @spec dimensions(Imagism.Image.t()) :: {integer(), integer()}
  def dimensions(_image), do: error()

  @spec encode(Imagism.Image.t()) :: {:error, any} | {:ok, binary()}
  def encode(_image), do: error()

  @spec rotate(Imagism.Image.t(), integer()) :: Imagism.Image.t()
  def rotate(_image, _rotation), do: error()
end
