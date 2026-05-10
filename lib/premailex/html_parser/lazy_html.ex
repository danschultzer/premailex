if Code.ensure_loaded?(LazyHTML) do
  defmodule Premailex.HTMLParser.LazyHTML do
    @moduledoc false

    @behaviour Premailex.HTMLParser

    @impl true
    @doc false
    def parse(html) do
      ~r/<html/i
      |> Regex.match?(html)
      |> case do
        true -> LazyHTML.from_document(html)
        false -> LazyHTML.from_fragment(html)
      end
      |> LazyHTML.to_tree()
      |> case do
        [tree] -> tree
        tree -> tree
      end
    end

    @impl true
    @doc false
    def all(tree, selector) do
      tree
      |> from_tree()
      |> LazyHTML.query(selector)
      |> LazyHTML.to_tree()
    end

    defp from_tree(tree) do
      tree
      |> List.wrap()
      |> LazyHTML.from_tree()
    end

    @impl true
    @doc false
    def filter(tree, selector) do
      tree = with_premailex_ids(tree)

      tree
      |> List.wrap()
      |> LazyHTML.from_tree()
      |> LazyHTML.query(selector)
      |> LazyHTML.to_tree()
      |> then(fn filter_nodes ->
        filter_tree(tree, filter_nodes)
      end)
    end

    @premailex_id_attr "data-premailex-id"

    defp with_premailex_ids(tree) do
      {tree, _index} = with_premailex_ids(tree, 0)

      tree
    end

    defp with_premailex_ids(nodes, index) when is_list(nodes) do
      Enum.map_reduce(nodes, index, &with_premailex_ids/2)
    end

    defp with_premailex_ids({tag, attrs, children}, index) do
      {tagged_children, next_index} = with_premailex_ids(children, index + 1)

      tagged_node =
        {tag, [{@premailex_id_attr, Integer.to_string(index)} | attrs], tagged_children}

      {tagged_node, next_index}
    end

    defp with_premailex_ids(node, index), do: {node, index}

    defp filter_tree(nodes, filter_nodes) when is_list(nodes) do
      nodes
      |> Enum.reduce([], fn node, acc ->
        case node in filter_nodes do
          true -> drop_whitespace(acc)
          false -> [filter_tree(node, filter_nodes) | acc]
        end
      end)
      |> Enum.reverse()
    end

    defp filter_tree({tag, attrs, children}, filter_nodes) do
      {
        tag,
        Enum.reject(attrs, fn {name, _value} -> name == @premailex_id_attr end),
        filter_tree(children, filter_nodes)
      }
    end

    defp filter_tree(node, _filter_nodes), do: node

    defp drop_whitespace([]), do: []

    defp drop_whitespace(["\n" <> _ = previous | rest]) do
      case String.trim(previous) == "" do
        true -> rest
        false -> [previous | rest]
      end
    end

    defp drop_whitespace(nodes), do: nodes

    @impl true
    @doc false
    def to_string(tree) do
      tree
      |> from_tree()
      |> LazyHTML.to_html()
    end

    @impl true
    @doc false
    def text(tree) do
      tree
      |> from_tree()
      |> LazyHTML.text()
    end
  end
end
