defmodule Differ.MixProject do
  use Mix.Project

  def project do
    [
      app: :differ,
      version: "0.1.1",
      source_url: "https://github.com/DanilaMihailov/differ",
      homepage_url: "https://github.com/DanilaMihailov/differ",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      # test coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]],
      # for testing protocols
      consolidate_protocols: Mix.env() != :test
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      # generating documentation (mix docs)
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      # test coverage (mix coveralls.html or mix test --cover)
      {:excoveralls, "~> 0.12.1", only: :test, runtime: false},
      # documentation check (mix inch)
      {:inch_ex, github: "rrrene/inch_ex", only: :docs, runtime: false},
      # static analysis (mix dialyzer)
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      # static analysis and style checks (mix credo --strict)
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      # benchmarks (mix run benchmarks/script_name.exs)
      {:benchee, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Small library for creating diffs and applying them."
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/DanilaMihailov/differ"}
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
