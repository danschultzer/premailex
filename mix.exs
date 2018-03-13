defmodule Premailex.Mixfile do
  use Mix.Project

  @version "0.1.5"

  def project do
    [
      app: :premailex,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Add inline styling to your HTML emails, and transform them to text",
      package: package(),

      # Docs
      name: "Premailex",
      docs: [
        source_ref: "v#{@version}",
        main: "Premailex",
        canonical: "http://hexdocs.pm/premailex",
        source_url: "https://github.com/danschultzer/premailex",
        extras: ["README.md"]
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
      {:floki, ">= 0.19.0 or < 0.21.0"},
      {:httpoison, "~> 0.13 or ~> 1.0"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:bypass, "~> 0.8", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
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
end
