defmodule Premailex.HTMLParser do
  @moduledoc """
  Module that provide HTML parsing API using an underlying HTML parser library.
  """

  @default_parser Premailex.HTMLParser.Floki
  @type html_tree :: tuple | list

  @doc """
  Parses a HTML string into an HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.parse("<html><head></head><body><h1>Title</h1></body></html>")
      {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}
  """
  @spec parse(String.t()) :: html_tree
  def parse(html) do
    apply(parser(), :parse, [html])
  end

  @doc """
  Searches an HTML tree for the selector.

  ## Examples

      iex> Premailex.HTMLParser.all({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}, "h1")
      [{"h1", [], ["Title"]}]
  """
  @spec all(html_tree, String.t()) :: [tuple]
  def all(tree, selector) do
    apply(parser(), :all, [tree, selector])
  end

  @doc """
  Turns an HTML tree into a string.

  ## Examples

      iex> Premailex.HTMLParser.to_string({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]})
      "<html><head></head><body><h1>Title</h1></body></html>"
  """
  @spec to_string(html_tree) :: String.t()
  def to_string(tree) do
    apply(parser(), :to_string, [tree])
  end

  @doc """
  Extracts text elements from the HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.text({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]})
      "Title"
  """
  @spec text(html_tree) :: String.t()
  def text(tree) do
    apply(parser(), :text, [tree])
  end

  defp parser() do
    Application.get_env(:premailex, :html_parser, @default_parser)
  end
end
