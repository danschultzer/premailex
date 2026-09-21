defmodule Premailex.Mixfile do
  use Mix.Project

  @source_url "https://github.com/danschultzer/premailex"
  @version "1.0.1"

  def project do
    [
      app: :premailex,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]],

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
      extra_applications: [:logger, :inets, :ssl, :xmerl]
    ]
  end

  defp deps do
    [
      {:floki, "~> 0.24", optional: true},
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
      # Mix task is only for maintainer use and should not be included in
      # the release.
      files: ~w(CHANGELOG.md lib/premailex lib/premailex.ex
                LICENSE mix.exs README.md priv/entities.txt)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "Premailex",
      canonical: "https://hexdocs.pm/premailex",
      source_url: @source_url,
      extras: [
        "CHANGELOG.md": [filename: "CHANGELOG"]
      ],
      skip_undefined_reference_warnings_on: [
        "CHANGELOG.md"
      ],
      groups_for_modules: [
        "HTML Parsers": [
          Premailex.HTMLParser,
          Premailex.HTMLParser.Xmerl,
          Premailex.HTMLParser.Floki,
          Premailex.HTMLParser.LazyHTML,
          Premailex.HTMLParser.Meeseeks
        ],
        HTTP: [
          Premailex.HTTPAdapter,
          Premailex.HTTPAdapter.Httpc
        ]
      ],
      # Mix task is only for maintainer use and should not be included in docs.
      filter_modules: fn
        Mix.Tasks.Premailex.Gen.Entities, _ -> false
        _module, _ -> true
      end
    ]
  end
end
