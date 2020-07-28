defmodule Imagism.MixProject do
  use Mix.Project

  def project do
    [
      app: :imagism,
      version: "0.1.0",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: rustler_crates(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Imagism, []}
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.21.1"},
      {:plug_cowboy, "~> 2.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:jason, "~> 1.2"}
    ]
  end

  defp rustler_crates do
    [
      imagism: [
        path: "native/imagism",
        mode: rustc_mode(Mix.env())
      ]
    ]
  end

  defp rustc_mode(:prod), do: :release
  defp rustc_mode(_), do: :debug
end
