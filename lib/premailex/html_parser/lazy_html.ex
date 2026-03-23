defmodule Premailex.HTMLParser.LazyHTML do
  @moduledoc false

  @behaviour Premailex.HTMLParser

  @impl true
  @doc false
  def parse(html) do
    is_document = Regex.match?(~r/<html|<HTML|<!DOCTYPE/i, html)

    result =
      if is_document do
        html
        |> LazyHTML.from_document()
        |> LazyHTML.to_tree(skip_whitespace_nodes: true)
      else
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.to_tree(skip_whitespace_nodes: true)
      end
      |> Enum.reject(&empty_text_node?/1)

    case result do
      [html] -> html
      html when is_list(html) -> html
      html -> html
    end
  end

  @impl true
  @doc false
  def all(tree, selector) do
    tree
    |> to_lazy_html()
    |> LazyHTML.query(selector)
    |> LazyHTML.to_tree(skip_whitespace_nodes: true)
  end

  @impl true
  @doc false
  def filter(tree, selector) do
    tree_list = normalize_tree(tree)

    filter_tree(tree_list, selector)
  end

  @impl true
  @doc false
  def to_string(tree) do
    tree
    |> to_lazy_html()
    |> LazyHTML.to_html(skip_whitespace_nodes: true)
  end

  @impl true
  @doc false
  def text(tree) do
    tree
    |> to_lazy_html()
    |> LazyHTML.text()
  end

  defp to_lazy_html(tree) when is_list(tree) do
    LazyHTML.from_tree(tree)
  end

  defp to_lazy_html(tree) when is_tuple(tree) do
    LazyHTML.from_tree([tree])
  end

  defp normalize_tree(tree) when is_list(tree), do: tree
  defp normalize_tree(tree) when is_tuple(tree), do: [tree]

  defp filter_tree(tree_list, selector) when is_list(tree_list) do
    tree_list
    |> Enum.map(fn node -> filter_node(node, selector) end)
    |> Enum.reject(fn node -> is_nil(node) or empty_text_node?(node) end)
  end

  defp empty_text_node?(""), do: true
  defp empty_text_node?(text) when is_binary(text), do: String.trim(text) == ""
  defp empty_text_node?(_), do: false

  defp filter_node(node, selector) when is_tuple(node) do
    {tag, attrs, children} = node

    node_without_children = {tag, attrs, []}
    lazy_html = LazyHTML.from_tree([node_without_children])
    matches = LazyHTML.query(lazy_html, selector)

    node_matches = LazyHTML.to_tree(matches) != []

    if node_matches do
      nil
    else
      filtered_children = filter_tree(children, selector)
      {tag, attrs, filtered_children}
    end
  end

  defp filter_node(node, _selector) when is_binary(node) do
    node
  end

  defp filter_node({:comment, _text} = node, _selector) do
    node
  end
end
