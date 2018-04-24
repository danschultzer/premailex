defmodule Premailex.HTMLParser.Floki do
  @moduledoc """
  API connection with Floki
  """
  alias Premailex.HTMLParser

  @doc false
  @spec parse(String.t()) :: HTMLParser.html_tree()
  def parse(html) do
    html
    |> retain_inline_whitespace()
    |> Floki.parse()
  end

  @doc false
  @spec all(HTMLParser.html_tree(), String.t()) :: [HTMLParser.html_tree()]
  def all(tree, selector) do
    Floki.find(tree, selector)
  end

  @doc false
  @spec delete_matching(HTMLParser.html_tree(), String.t()) :: [HTMLParser.html_tree()]
  def delete_matching(tree, selector) do
    Floki.filter_out(tree, selector)
  end

  @doc false
  @spec to_string(HTMLParser.html_tree()) :: String.t()
  def to_string(tree) do
    Floki.raw_html(tree)
  end

  @spec text(HTMLParser.html_tree()) :: String.t()
  def text(tree) do
    Floki.text(tree)
  end

  # """
  # This is a tempory fix until mochweb (or floki) has been updated
  # to correctly handle whitespace text nodes: https://github.com/mochi/mochiweb/issues/166
  # """
  defp retain_inline_whitespace(html), do: String.replace(html, ~r/\>[ ]+\</, ">&#32;<")
end
