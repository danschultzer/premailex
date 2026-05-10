defmodule Premailex.HTMLParser do
  @moduledoc """
  Module that provide HTML parsing API using an underlying HTML parser library.

  By default, premailex will try to use Floki, then LazyHTML, then Meeseeks
  (in that order) based on what's available.

  You can explicitly configure which parser to use in your config:

      config :premailex, html_parser: Premailex.HTMLParser.LazyHTML
  """

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
  def parse(html), do: html_parser().parse(html)

  defp html_parser do
    case Application.get_env(:premailex, :html_parser) || default_html_parser!() do
      mod when is_atom(mod) -> mod
      other -> raise "Invalid html_parser, got: #{inspect(other)}"
    end
  end

  defp default_html_parser! do
    cond do
      Code.ensure_loaded?(Floki) ->
        Premailex.HTMLParser.Floki

      Code.ensure_loaded?(LazyHTML) ->
        Premailex.HTMLParser.LazyHTML

      Code.ensure_loaded?(Meeseeks) ->
        Premailex.HTMLParser.Meeseeks

      true ->
        raise """
        No HTML parser is available. Please add at least one of the following dependencies to your mix.exs:

        - {:floki, "~> 0.19"}
        - {:lazy_html, "~> 0.1.11"}
        - {:meeseeks, "~> 0.11"}

        Or explicitly configure a parser:
        config :premailex, html_parser: Premailex.HTMLParser.Floki
        """
    end
  end

  @doc """
  Searches an HTML tree for the selector.

  ## Examples

      iex> Premailex.HTMLParser.all({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}, "h1")
      [{"h1", [], ["Title"]}]
  """
  @spec all(html_tree(), selector()) :: [html_tree()]
  def all(tree, selector), do: html_parser().all(tree, selector)

  @doc """
  Filters elements matching the selector from the HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.filter([{"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}], "h1")
      [{"html", [], [{"head", [], []}, {"body", [], []}]}]
  """
  @spec filter(html_tree(), selector()) :: [html_tree()]
  def filter(tree, selector), do: html_parser().filter(tree, selector)

  @doc """
  Turns an HTML tree into a string.

  ## Examples

      iex> Premailex.HTMLParser.to_string({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]})
      "<html><head></head><body><h1>Title</h1></body></html>"
  """
  @spec to_string(html_tree()) :: binary()
  def to_string(tree), do: html_parser().to_string(tree)

  @doc """
  Extracts text elements from the HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.text({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]})
      "Title"
  """
  @spec text(html_tree()) :: binary()
  def text(tree), do: html_parser().text(tree)
end
