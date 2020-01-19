defmodule Differ.MixProject do
  use Mix.Project

  def project do
    [
      app: :differ,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12.1", only: :test},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md"
      ]
    ]
  end
end
