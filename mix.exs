defmodule Geolite.MixProject do
  use Mix.Project

  def project do
    [
      app: :geolite,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Geolite.Application, []}
    ]
  end

  # defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:locus, "~> 2.3", only: [:dev, :bench]},
      {:benchee, "~> 1.1", only: [:dev, :bench]},
      {:geolix, "~> 2.0", only: [:dev, :bench]},
      {:geolix_adapter_mmdb2, "~> 0.6.0", only: [:dev, :bench]},
      {:exqlite, "~> 0.11.4"},
      {:nimble_csv, "~> 1.2", only: [:dev, :test]}
    ]
  end
end
