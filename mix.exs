defmodule Premailex.Mixfile do
  use Mix.Project

  @version "0.3.13"

  def project do
    [
      app: :premailex,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Add inline styling to your HTML emails, and transform them to text",
      package: package(),

      # Docs
      name: "Premailex",
      docs: docs(),

      xref: [exclude: [:certifi, :httpc, Meeseeks, Meeseeks.Document, Meeseeks.Selector.CSS, :ssl_verify_hostname]]
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
      {:floki, "~> 0.19"},

      {:meeseeks, "~> 0.11", optional: true},
      {:certifi, ">= 0.0.0", optional: true},
      {:ssl_verify_fun, ">= 0.0.0", optional: true},

      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Dan Shultzer"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/danschultzer/premailex"},
      files: ~w(lib LICENSE mix.exs README.md)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      canonical: "http://hexdocs.pm/premailex",
      source_url: "https://github.com/danschultzer/premailex",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
