defmodule Premailex.HTMLParser do
  @moduledoc """
  Module that provide HTML parsing API using an underlying HTML parser library.
  """

  @default_parser Premailex.HTMLParser.Floki

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
    Application.get_env(:premailex, :html_parser, @default_parser)
  end
end
