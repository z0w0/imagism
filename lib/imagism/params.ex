defmodule Imagism.Params do
  @moduledoc """
  The image processing parameters that specify how to process an image.
  """
  @type t() :: %Imagism.Params{}

  defstruct w: nil,
            h: nil,
            fit: nil,
            brighten: nil,
            blur: nil,
            flip: nil

  defp parse_int(str) do
    if str == nil do
      nil
    else
      case Integer.parse(str) do
        :error -> nil
        {integer, _} -> integer
      end
    end
  end

  defp parse_float(str) do
    if str == nil do
      nil
    else
      case Float.parse(str) do
        :error -> nil
        {float, _} -> float
      end
    end
  end

  @doc """
  Creates the image params from unstructured query parameters.
  """
  @spec new(map) :: Imagism.Params.t()
  def new(query_params) do
    w = parse_int(query_params["w"])
    h = parse_int(query_params["h"])
    brighten = parse_int(query_params["brighten"])
    blur = parse_float(query_params["blur"])
    flip = query_params["flip"]
    fit = query_params["fit"]

    %Imagism.Params{
      w: w,
      h: h,
      fit: fit,
      brighten: brighten,
      blur: blur,
      flip: flip
    }
  end
end
