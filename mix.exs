defmodule Differ.MixProject do
  use Mix.Project

  def project do
    [
      app: :differ,
      version: "0.1.0",
      source_url: "https://github.com/DanilaMihailov/Differ",
      homepage_url: "https://github.com/DanilaMihailov/Differ",
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
      # generating documentation (mix docs)
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      # test coverage (mix coveralls.html or mix test --cover)
      {:excoveralls, "~> 0.12.1", only: :test},
      # documentation check (mix inch)
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},
      # static analysis (mix dialyzer)
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      # static analysis and style checks (mix credo --strict)
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      # benchmarks (mix run benchmarks/script_name.exs)
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp docs do
    [
      main: "readme",
      groups_for_modules: [
        Protocols: ~r/able/
      ],
      extras: [
        "README.md"
      ]
    ]
  end
end
