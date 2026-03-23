defmodule Premailex.HTMLParser do
  @moduledoc """
  Module that provide HTML parsing API using an underlying HTML parser library.

  By default, premailex will try to use Floki, then Meeseeks, then LazyHTML
  (in that order) based on what's available. You can also explicitly configure
  which parser to use in your config:

      config :premailex, html_parser: Premailex.HTMLParser.LazyHTML

  At least one HTML parser dependency must be available:
  - `{:floki, "~> 0.19"}` (default if available)
  - `{:meeseeks, "~> 0.11"}`
  - `{:lazy_html, "~> 0.1.8"}`
  """

  @parsers_in_order [
    Premailex.HTMLParser.Floki,
    Premailex.HTMLParser.Meeseeks,
    Premailex.HTMLParser.LazyHTML
  ]

  @type html_tree :: tuple() | list()
  @type selector :: binary()

  @callback parse(binary()) :: html_tree()
  @callback all(html_tree(), selector()) :: [html_tree()]
  @callback filter(html_tree(), selector()) :: [html_tree()]
  @callback to_string(html_tree()) :: binary()
  @callback text(html_tree()) :: binary()

  @doc """
  Parses a HTML string into an HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.parse("<html><head></head><body><h1>Title</h1></body></html>")
      {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}
  """
  @spec parse(binary()) :: html_tree()
  def parse(html), do: parser().parse(html)

  @doc """
  Searches an HTML tree for the selector.

  ## Examples

      iex> Premailex.HTMLParser.all({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}, "h1")
      [{"h1", [], ["Title"]}]
  """
  @spec all(html_tree(), selector()) :: [html_tree()]
  def all(tree, selector), do: parser().all(tree, selector)

  @doc """
  Filters elements matching the selector from the HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.filter([{"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}], "h1")
      [{"html", [], [{"head", [], []}, {"body", [], []}]}]
  """
  @spec filter(html_tree(), selector()) :: [html_tree()]
  def filter(tree, selector), do: parser().filter(tree, selector)

  @doc """
  Turns an HTML tree into a string.

  ## Examples

      iex> Premailex.HTMLParser.to_string({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]})
      "<html><head></head><body><h1>Title</h1></body></html>"
  """
  @spec to_string(html_tree()) :: binary()
  def to_string(tree), do: parser().to_string(tree)

  @doc """
  Extracts text elements from the HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.text({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]})
      "Title"
  """
  @spec text(html_tree()) :: binary()
  def text(tree), do: parser().text(tree)

  defp parser do
    case Application.get_env(:premailex, :html_parser) do
      nil ->
        # No explicit config, try to find an available parser
        find_available_parser()

      configured_parser ->
        # User explicitly configured a parser, verify it's available
        if parser_available?(configured_parser) do
          configured_parser
        else
          raise """
          The configured HTML parser #{inspect(configured_parser)} is not available.

          Please ensure the corresponding dependency is added to your mix.exs:
          - For Floki: {:floki, "~> 0.19"}
          - For Meeseeks: {:meeseeks, "~> 0.11"}
          - For LazyHTML: {:lazy_html, "~> 0.1.8"}

          Or configure a different parser in your config:
          config :premailex, html_parser: Premailex.HTMLParser.Floki
          """
        end
    end
  end

  # Find the first available parser in order of preference
  defp find_available_parser do
    case Enum.find(@parsers_in_order, &parser_available?/1) do
      nil ->
        raise """
        No HTML parser is available. Please add at least one of the following dependencies to your mix.exs:

        - {:floki, "~> 0.19"}
        - {:meeseeks, "~> 0.11"}
        - {:lazy_html, "~> 0.1.8"}

        Or explicitly configure a parser:
        config :premailex, html_parser: Premailex.HTMLParser.Floki
        """

      parser ->
        parser
    end
  end

  # Check if a parser module is available by verifying its dependencies are loaded
  defp parser_available?(Premailex.HTMLParser.Floki) do
    Code.ensure_loaded?(Floki)
  end

  defp parser_available?(Premailex.HTMLParser.Meeseeks) do
    Code.ensure_loaded?(Meeseeks)
  end

  defp parser_available?(Premailex.HTMLParser.LazyHTML) do
    Code.ensure_loaded?(LazyHTML)
  end

  defp parser_available?(_), do: false
end
