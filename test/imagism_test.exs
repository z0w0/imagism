defmodule ImagismTest do
  use ExUnit.Case
  doctest Imagism

  defp test_query(query) do
    %{body: body} =
      HTTPoison.get!("http://localhost:8000/sloth.jpg?#{query}", [], recv_timeout: 10000)

    assert File.read!(Path.join(__DIR__, "images/sloth-#{query}.jpg")) == body
  end

  test "?blur=0.1", do: test_query("blur=0.1")
  test "?brighten=-100", do: test_query("brighten=-100")
  test "?brighten=100", do: test_query("brighten=100")
  test "?contrast=50", do: test_query("contrast=50")
  test "?flip=h", do: test_query("flip=h")
  test "?flip=v", do: test_query("flip=v")
  test "?flip=hv", do: test_query("flip=hv")
  test "?rotate=90", do: test_query("rotate=90")
  test "?rotate=180", do: test_query("rotate=180")
  test "?rotate=270", do: test_query("rotate=270")
  test "?w=300", do: test_query("w=300")
  test "?w=300&h=500", do: test_query("w=300&h=500")
  test "?w=300&resize=crop", do: test_query("w=300&resize=crop")
  test "?w=300&resize=crop&crop=bottom,left", do: test_query("w=300&resize=crop&crop=bottom,left")

  test "?w=300&resize=crop&crop=bottom,right",
    do: test_query("w=300&resize=crop&crop=bottom,right")

  test "?w=300&resize=crop&crop=top,left", do: test_query("w=300&resize=crop&crop=top,left")
  test "?w=300&resize=crop&crop=top,right", do: test_query("w=300&resize=crop&crop=top,right")
  test "?w=300&resize=exact", do: test_query("w=300&resize=exact")
end
