defmodule Premailex.Mixfile do
  use Mix.Project

  @source_url "https://github.com/danschultzer/premailex"
  @version "0.3.20"

  def project do
    [
      app: :premailex,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [
        exclude: [
          :certifi,
          :httpc,
          Meeseeks,
          Meeseeks.Document,
          Meeseeks.Selector.CSS,
          LazyHTML,
          :ssl_verify_hostname
        ]
      ],

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
      {:floki, "~> 0.19", optional: true},
      {:lazy_html, "~> 0.1.11", optional: true},
      {:meeseeks, "~> 0.11", optional: true},
      {:certifi, ">= 0.0.0", optional: true},
      {:ssl_verify_fun, ">= 0.0.0", optional: true},

      # Development and test
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:test_server, "~> 0.1.5", only: [:test]},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Dan Schultzer"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Sponsor" => "https://github.com/sponsors/danschultzer"
      },
      files: ~w(lib LICENSE mix.exs README.md)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "Premailex",
      canonical: "http://hexdocs.pm/premailex",
      source_url: @source_url,
      extras: [
        "CHANGELOG.md": [filename: "CHANGELOG"]
      ],
      skip_undefined_reference_warnings_on: [
        "CHANGELOG.md"
      ],
      groups_for_modules: [
        Parsers: [
          Premailex.CSSParser,
          Premailex.HTMLParser
        ],
        HTTP: [
          Premailex.HTTPAdapter,
          Premailex.HTTPAdapter.Httpc
        ]
      ]
    ]
  end
end
