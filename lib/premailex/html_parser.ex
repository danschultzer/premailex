defmodule Premailex.HTMLParser do
  @moduledoc """
  Module that provide HTML parsing API using an underlying HTML parser library.
  """

  @default_parser Premailex.HTMLParser.Floki

  @doc """
  Parses a HTML string into an HTML tree.

  ## Examples

      iex> Premailex.HTMLParser.parse("<html><head></head><body><h1>Title</h1></body></html>")
      {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}
  """
  @spec parse(String.t()) :: tuple
  def parse(html) do
    apply(parser(), :parse, [html])
  end

  @doc """
  Searches an HTML tree for the selector.

  ## Examples

      iex> Premailex.HTMLParser.all({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}, "h1")
      [{"h1", [], ["Title"]}]
  """
  @spec all(tuple, String.t()) :: [tuple]
  def all(tree, selector) do
    apply(parser(), :all, [tree, selector])
  end

  @doc """
  Turns an HTML tree into a string.

  ## Examples

      iex> Premailex.HTMLParser.to_string({"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]})
      "<html><head></head><body><h1>Title</h1></body></html>"
  """
  @spec to_string(tuple) :: String.t()
  def to_string(tree) do
    apply(parser(), :to_string, [tree])
  end

  defp parser() do
    Application.get_env(:premailex, :html_parser, @default_parser)
  end
end
