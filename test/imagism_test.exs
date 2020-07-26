defmodule ImagismTest do
  use ExUnit.Case
  doctest Imagism

  test "brighten an image" do
    {:ok, image} = Imagism.open(Path.join([__DIR__, "images/sloth.jpg"]))

    {:ok, _} =
      Imagism.brighten(image, 100)
      |> Imagism.save(Path.join([__DIR__, "images/sloth-brighten-test.jpg"]))
  end
end
