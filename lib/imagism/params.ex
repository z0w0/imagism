defmodule Imagism.Params do
  @moduledoc """
  The image processing parameters that specify how to process an image.
  """
  @type t() :: %Imagism.Params{}

  defstruct w: nil,
            h: nil,
            resize: nil,
            brighten: nil,
            contrast: nil,
            blur: nil,
            flip: nil,
            crop: nil,
            rotate: nil

  defp parse_int(str) when is_binary(str) or is_nil(str) do
    if str == nil do
      nil
    else
      case Integer.parse(str) do
        :error -> nil
        {integer, _} -> integer
      end
    end
  end

  defp parse_float(str) when is_binary(str) or is_nil(str) do
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
    contrast = parse_int(query_params["contrast"])
    blur = parse_float(query_params["blur"])
    rotate = parse_int(query_params["rotate"])

    flip =
      case query_params["flip"] do
        "h" -> :h
        "v" -> :v
        "hv" -> :hv
        _ -> nil
      end

    resize =
      case query_params["resize"] do
        "crop" -> :crop
        "exact" -> :exact
        _ -> :fit
      end

    crop =
      String.split(query_params["crop"] || "center", ",")
      |> Enum.map(fn crop_type ->
        case crop_type do
          "top" -> :top
          "bottom" -> :bottom
          "left" -> :left
          "right" -> :right
          _ -> :unknown
        end
      end)

    %Imagism.Params{
      w: w,
      h: h,
      resize: resize,
      brighten: brighten,
      contrast: contrast,
      blur: blur,
      flip: flip,
      crop: crop,
      rotate: rotate
    }
  end
end
