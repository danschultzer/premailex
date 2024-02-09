defmodule Premailex.HTMLParser.Floki do
  @moduledoc false
  alias Premailex.HTMLParser

  @behaviour HTMLParser

  @impl true
  @doc false
  def parse(html) do
    html = retain_inline_whitespace(html)
    args = [html]

    "< 0.24.0"
    |> floki_version_match?()
    |> case do
      true -> apply(Floki, :parse, args)
      false -> apply(Floki, :parse_document, args)
    end
    |> case do
      {:ok, [html]} -> html
      {:ok, document} -> document
      any -> any
    end
  end

  defp floki_version_match?(req) do
    case :application.get_key(:floki, :vsn) do
      {:ok, actual} ->
        actual
        |> List.to_string()
        |> Version.match?(req)

      _any ->
        false
    end
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
  def text(tree) when is_binary(tree) do
    case Floki.parse_document(tree) do
      {:ok, document} -> Floki.text(document)
      error -> error
    end
  end

  def text(tree), do: Floki.text(tree)

  # """
  # This is a tempory fix until mochweb (or floki) has been updated
  # to correctly handle whitespace text nodes: https://github.com/mochi/mochiweb/issues/166
  # """
  defp retain_inline_whitespace(html), do: String.replace(html, ~r/\>[ ]+\</, ">&#32;<")
end
