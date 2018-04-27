if Code.ensure_loaded?(Meeseeks) do
  defmodule Premailex.HTMLParser.Meeseeks do
    @moduledoc false

    require Logger
    import Meeseeks.CSS
    alias Premailex.HTMLParser
    alias Meeseeks.Selector.CSS.Parser.ParseError
    alias Meeseeks.Document

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

    def delete_matching(tree, selector) do
      tree
      |> Meeseeks.all(css("#{selector}"))
      |> Enum.reduce(Meeseeks.parse(tree), fn e, acc ->
        Document.delete_node(acc, e.id)
      end)
      |> Meeseeks.tree()
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
  end
end
