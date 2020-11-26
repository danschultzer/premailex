defmodule Premailex.HTMLParser.Meeseeks do
  @moduledoc false

  require Logger

  alias Premailex.HTMLParser
  alias Meeseeks.{Document, Selector.CSS}

  @behaviour HTMLParser

  @impl true
  @doc false
  def parse(html) do
    html
    |> Meeseeks.parse()
    |> Meeseeks.tree()
    |> case do
      [html] -> html
      html -> html
    end
  end

  @impl true
  @doc false
  def all(tree, selector) do
    selector = CSS.compile_selectors(selector)

    tree
    |> Meeseeks.parse(:tuple_tree)
    |> Meeseeks.all(selector)
    |> Enum.map(&Meeseeks.tree/1)
  rescue
    e in Meeseeks.Error ->
      Logger.warn("Meeseeks error: " <> inspect(e))
      []
  end

  @impl true
  @doc false
  def to_string(tree) do
    tree
    |> Meeseeks.parse(:tuple_tree)
    |> Meeseeks.html()
  end

  @impl true
  @doc false
  def text(text) when is_binary(text), do: text
  def text(list) when is_list(list), do: Enum.map_join(list, "", &text/1)
  def text({:comment, _text}), do: ""
  def text({_element, _attrs, children}), do: text(children)

  @impl true
  @doc false
  def filter(tree, selector) do
    selector = CSS.compile_selectors(selector)
    tree     = Meeseeks.parse(tree, :tuple_tree)

    tree
    |> Meeseeks.all(selector)
    |> Enum.reduce(tree, fn e, acc ->
      Document.delete_node(acc, e.id)
    end)
    |> Meeseeks.tree()
  end
end
