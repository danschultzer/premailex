defmodule Premailex.HTMLParser.Floki do
  @moduledoc false
  alias Premailex.HTMLParser

  @behaviour HTMLParser

  @impl true
  @doc false
  def parse(html) do
    html
    |> retain_inline_whitespace()
    |> Floki.parse()
  end

  @impl true
  @doc false
  def all(tree, selector), do: Floki.find(tree, selector)

  @impl true
  @doc false
  def filter(tree, selector), do: Floki.filter_out(tree, selector)

  @impl true
  @doc false
  def to_string(tree), do: Floki.raw_html(tree)

  @impl true
  @doc false
  def text(tree), do: Floki.text(tree)

  # """
  # This is a tempory fix until mochweb (or floki) has been updated
  # to correctly handle whitespace text nodes: https://github.com/mochi/mochiweb/issues/166
  # """
  defp retain_inline_whitespace(html), do: String.replace(html, ~r/\>[ ]+\</, ">&#32;<")
end
