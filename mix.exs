defmodule Premailex.Mixfile do
  use Mix.Project

  @version "0.3.17"

  def project do
    [
      app: :premailex,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [:certifi, :httpc, Meeseeks, Meeseeks.Document, Meeseeks.Selector.CSS, :ssl_verify_hostname]],

      # Hex
      description: "Add inline styling to your HTML emails, and transform them to text",
      package: package(),

      # Docs
      name: "Premailex",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:floki, "~> 0.19"},

      {:meeseeks, "~> 0.11", optional: true},
      {:certifi, ">= 0.0.0", optional: true},
      {:ssl_verify_fun, ">= 0.0.0", optional: true},

      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:test_server, "~> 0.1.5", only: [:test]}
    ]
  end

  defp package do
    [
      maintainers: ["Dan Schultzer"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/danschultzer/premailex",
        "Sponsor" => "https://github.com/sponsors/danschultzer"
      },
      files: ~w(lib LICENSE mix.exs README.md)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "README",
      canonical: "http://hexdocs.pm/premailex",
      source_url: "https://github.com/danschultzer/premailex",
      extras: [
        "README.md": [filename: "README"],
        "CHANGELOG.md": [filename: "CHANGELOG"]
      ]
    ]
  end
end
