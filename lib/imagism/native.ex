defmodule Imagism.Native do
  @moduledoc """
  The native module that calls into the imagism crate via Rustler.
  """
  use Rustler, otp_app: :imagism, crate: :imagism

  def open(_path), do: error()
  def save(_image, _path), do: error()
  def brighten(_image, _value), do: error()
  def blur(_image, _sigma), do: error()
  def resize(_image, _w, _h), do: error()
  def resize_exact(_image, _w, _h), do: error()
  def crop(_image, _x, _y, _w, _h), do: error()
  def content_type(_image), do: error()
  def dimensions(_image), do: error()
  def encode(_image), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
