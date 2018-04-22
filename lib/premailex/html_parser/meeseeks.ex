defmodule Premailex.HTMLParser.Meeseeks do
  @moduledoc """
  API connection with Meeseeks
  """

  require Logger
  import Meeseeks.CSS
  alias Premailex.HTMLParser
  alias Meeseeks.{Selector.CSS.Parser.ParseError}

  @doc false
  @spec parse(String.t()) :: HTMLParser.html_tree()
  def parse(html) do
    html
    |> Meeseeks.parse()
    |> Meeseeks.tree()
    |> case do
      [html] -> html
      html -> html
    end
    |> sanitize()
  end

  @doc false
  @spec all(HTMLParser.html_tree(), String.t()) :: [HTMLParser.html_tree()]
  def all(tree, selector) do
    try do
      tree
      |> Meeseeks.all(css("#{selector}"))
      |> Enum.map(&Meeseeks.tree/1)
    rescue
      e in ParseError ->
        Logger.warn("Meeseeks CSS ParseError: " <> e.message)
        []
    end
  end

  @doc false
  @spec to_string(HTMLParser.html_tree()) :: String.t()
  def to_string(tree) do
    tree
    |> Meeseeks.parse()
    |> Meeseeks.html()
  end

  @doc false
  @spec text(HTMLParser.html_tree()) :: String.t()
  def text(text) when is_binary(text), do: text
  def text(list) when is_list(list), do: Enum.map_join(list, "", &text/1)
  def text({_element, _attrs, children}), do: text(children)

  defp sanitize(list) when is_list(list) do
    list
    |> Enum.map(&sanitize/1)
    |> Enum.reject(&is_empty?/1)
  end

  defp sanitize({elem, attr, children}) do
    {elem, attr, sanitize(children)}
  end

  defp sanitize(any), do: any

  defp is_empty?(text) when is_binary(text) do
    String.trim(text) == ""
  end

  defp is_empty?(_any), do: false
end
