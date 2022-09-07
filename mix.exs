defmodule Geolite.MixProject do
  use Mix.Project

  def project do
    [
      app: :geolite,
      version: "0.1.0",
      elixir: "~> 1.13",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:locus, "~> 2.3", only: [:bench]},
      {:benchee, "~> 1.1", only: [:bench]},
      {:geolix, "~> 2.0", only: [:bench]},
      {:exqlite, "~> 0.11.4"},
      {:nimble_csv, "~> 1.2", only: [:dev, :test]}
    ]
  end
end
