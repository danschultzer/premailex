defmodule Premailex.DOM do
  @supported_pseudo_classes ~w(first-child last-child only-child first-of-type
                               last-of-type only-of-type empty root nth-child
                               nth-of-type nth-last-child nth-last-of-type)

  @moduledoc """
  DOM manipulation.

  Supports the following pseudo-classes: #{Enum.map_join(@supported_pseudo_classes, ", ", &"`:#{&1}`")}.

  Functional pseudo-classes that take arguments (e.g. `:nth-child`) support
  the An+B syntax.

  ## Selector support limitations

    * Pseudo-classes that are not supported will never match and will emit a
      debug log.

    * Functional pseudo-classes that take arguments do not support the
      `of <complex-selector-list>` clause; the entire expression is treated as
      invalid and the rule is ignored.

    * The column combinator (`||`) parses but never matches and emits a debug
      log.
  """

  alias Premailex.CSSParser

  require Logger

  @type tag_name :: String.t()
  @type needle :: Premailex.html_element() | tag_name() | :comment
  @type selector :: String.t()

  @typedoc """
  A selector item is a map that contains a `:selector` key.

  Any additional keys attached by the caller are preserved during traversal
  and returned as part of the matched selector items in the
  `traverse_with_matching_items/3` callback.
  """
  @type selector_item :: %{required(:selector) => selector(), optional(any) => any}

  @doc """
  Traverses HTML elements searching for needles and calls the provided function
  on each match.

  The elements are traversed depth-first, replacing each matching node with the
  function's return value.

  ## Examples

      iex> Premailex.DOM.replace_all_matches([{"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Second paragraph"]}]}], "p", fn {name, attrs, _children} -> {name, attrs, ["Updated"]} end)
      [{"div", [], [{"p", [], ["Updated"]}, {"p", [], ["Updated"]}]}]

      iex> Premailex.DOM.replace_all_matches({"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Second paragraph"]}]}, {"p", [], ["Second paragraph"]}, fn {name, attrs, _children} -> {name, attrs, ["Updated"]} end)
      {"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Updated"]}]}

      iex> Premailex.DOM.replace_all_matches([{"div", [], [{:comment, "This is a comment"}, {"p", [], ["Paragraph"]}]}], :comment, fn {:comment, _comment} -> {:comment, "Updated"} end)
      [{"div", [], [{:comment, "Updated"}, {"p", [], ["Paragraph"]}]}]
  """
  @spec replace_all_matches(
          Premailex.html_tree() | Premailex.html_element(),
          needle() | [needle()],
          (Premailex.html_node() ->
             Premailex.html_node())
        ) ::
          Premailex.html_tree() | Premailex.html_element()
  def replace_all_matches(tree_or_element, needle_or_needles, fun),
    do: do_replace_all_matches(tree_or_element, List.wrap(needle_or_needles), fun)

  defp do_replace_all_matches(children, needles, fun) when is_list(children),
    do: Enum.map(children, &do_replace_all_matches(&1, needles, fun))

  defp do_replace_all_matches({name, attrs, children} = element, needles, fun) do
    cond do
      name in needles -> fun.(element)
      element in needles -> fun.(element)
      true -> {name, attrs, do_replace_all_matches(children, needles, fun)}
    end
  end

  defp do_replace_all_matches({:comment, _comment} = element, needles, fun) do
    case :comment in needles do
      true -> fun.(element)
      false -> element
    end
  end

  defp do_replace_all_matches(other, _needles, _fun), do: other

  @doc """
  Traverses HTML elements until the first match of a needle.

  The elements are traversed depth-first, and the first matching node is
  replaced with the function's return value.

  ## Examples

      iex> Premailex.DOM.replace_first_match([{"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Second paragraph"]}]}], "p", fn {name, attrs, _children} -> {name, attrs, ["Updated"]} end)
      [{"div", [], [{"p", [], ["Updated"]}, {"p", [], ["Second paragraph"]}]}]
  """
  @spec replace_first_match(
          Premailex.html_tree() | Premailex.html_element(),
          needle(),
          (Premailex.html_node() -> Premailex.html_node())
        ) ::
          Premailex.html_tree() | Premailex.html_element()
  def replace_first_match(tree_or_element, needle, fun) do
    case do_replace_first_match(tree_or_element, needle, fun) do
      {:halt, tree_or_element} -> tree_or_element
      tree_or_element -> tree_or_element
    end
  end

  defp do_replace_first_match({:comment, _comment} = element, :comment, fun) do
    {:halt, fun.(element)}
  end

  defp do_replace_first_match({name, _attrs, _children} = element, name, fun) do
    {:halt, fun.(element)}
  end

  defp do_replace_first_match({_, _, _} = element, element, fun) do
    {:halt, fun.(element)}
  end

  defp do_replace_first_match({name, attrs, children}, needle, fun) do
    case do_replace_first_match(children, needle, fun) do
      {:halt, new_children} -> {:halt, {name, attrs, new_children}}
      new_children -> {name, attrs, new_children}
    end
  end

  defp do_replace_first_match(tree, needle, fun) when is_list(tree),
    do: do_replace_first_match(tree, needle, fun, [])

  defp do_replace_first_match(other, _needle, _fun), do: other

  defp do_replace_first_match([], _needle, _fun, acc), do: Enum.reverse(acc)

  defp do_replace_first_match([child | rest], needle, fun, acc) do
    case do_replace_first_match(child, needle, fun) do
      {:halt, result} -> {:halt, Enum.reverse([result | acc]) ++ rest}
      other -> do_replace_first_match(rest, needle, fun, [other | acc])
    end
  end

  @doc """
  Traverses HTML elements, calling the provided function on each element
  matching one or more selector items and replacing it with the function's
  return value.

  ## Examples

      iex> Premailex.DOM.traverse_with_matching_items(
      ...>   {"div", [], [{"p", [], ["Hi"]}]},
      ...>   [%{selector: "p"}],
      ...>   fn {tag, attrs, children}, _matched ->
      ...>     {tag, [{"matched", ""} | attrs], children}
      ...>   end)
      {"div", [], [{"p", [{"matched", ""}], ["Hi"]}]}
  """
  @spec traverse_with_matching_items(
          Premailex.html_tree() | Premailex.html_element(),
          [selector_item()],
          (Premailex.html_element(), nonempty_list(selector_item()) ->
             Premailex.html_element())
        ) ::
          Premailex.html_tree() | Premailex.html_element()
  def traverse_with_matching_items(tree_or_element, [], _fun), do: tree_or_element

  def traverse_with_matching_items(tree, selector_items, fun) when is_list(tree) do
    selector_items_table = build_selector_items_lookup_table(selector_items)

    do_traverse_with_matching_items(tree, selector_items_table, fun, [])
  end

  def traverse_with_matching_items({_, _, _} = element, selector_items, fun) do
    [result] = traverse_with_matching_items([element], selector_items, fun)

    result
  end

  defp build_selector_items_lookup_table(selector_items) do
    initial = %{by_tag: %{}, by_class: %{}, by_id: %{}, universal: []}

    selector_items
    |> Enum.with_index()
    |> Enum.reduce(initial, fn {selector_item, index}, selector_items_table ->
      compiled_groups = compile_selector_groups(selector_item.selector)

      selector_item =
        selector_item
        |> Map.put(:compiled_selector_groups, compiled_groups)
        |> Map.put(:source_index, index)

      Enum.reduce(
        compiled_groups,
        selector_items_table,
        &register_table_selector_item(&2, &1, selector_item)
      )
    end)
  end

  defp compile_selector_groups(selector) do
    selector
    |> CSSParser.parse_selector_groups()
    |> Enum.map(fn group ->
      Enum.map(group, fn step ->
        class_patterns =
          Enum.map(step.classes, &:binary.compile_pattern(<<" ", &1::binary, " ">>))

        Enum.each(step.pseudos, &warn_unsupported_pseudo/1)

        Map.put(step, :class_patterns, class_patterns)
      end)
    end)
  end

  defp warn_unsupported_pseudo(%{kind: :pseudo_element}), do: :ok

  defp warn_unsupported_pseudo(%{
         kind: :pseudo_class,
         nth: :invalid,
         name: name,
         expression: expr
       }) do
    Logger.debug(fn -> "Invalid expression for :#{name}(#{expr}). Ignoring." end)
  end

  defp warn_unsupported_pseudo(%{kind: :pseudo_class, name: name})
       when name in @supported_pseudo_classes,
       do: :ok

  defp warn_unsupported_pseudo(%{kind: :pseudo_class, name: name}) do
    Logger.debug(fn -> "Pseudo-class :#{name} is not implemented. Ignoring." end)
  end

  defp register_table_selector_item(selector_items_table, [target | _ancestors], item) do
    case target do
      %{id: id} when not is_nil(id) ->
        update_selector_items_table(selector_items_table, [:by_id, id], item)

      %{tag: tag} when not is_nil(tag) and tag != "*" ->
        update_selector_items_table(selector_items_table, [:by_tag, tag], item)

      %{classes: [class | _]} ->
        update_selector_items_table(selector_items_table, [:by_class, class], item)

      _target ->
        %{selector_items_table | universal: [item | selector_items_table.universal]}
    end
  end

  defp update_selector_items_table(selector_items_table, path, selector_item) do
    update_in(selector_items_table, path, fn
      nil -> [selector_item]
      selector_items -> [selector_item | selector_items]
    end)
  end

  defp do_traverse_with_matching_items(nodes, selector_items_table, fun, ancestors)
       when is_list(nodes) do
    {total, by_tag} = count_siblings(nodes)

    {result, _traversal_state} =
      Enum.map_reduce(nodes, initial_traversal_state(), fn
        {tag, attrs, children} = element, traversal_state ->
          traversal_state = next_traversal_state(traversal_state, tag)
          context = element_context(element, traversal_state, ancestors, total, by_tag)

          traversed_children =
            do_traverse_with_matching_items(children, selector_items_table, fun, [
              context | ancestors
            ])

          element =
            selector_items_table
            |> applicable_selector_items(tag, attrs)
            |> Enum.filter(fn item ->
              Enum.any?(
                item.compiled_selector_groups,
                &matches_selector_group?(context, &1, ancestors)
              )
            end)
            |> restore_source_order()
            |> case do
              [] -> {tag, attrs, traversed_children}
              matched_items -> fun.({tag, attrs, traversed_children}, matched_items)
            end

          {element, push_previous_sibling(traversal_state, context)}

        node, traversal_state ->
          {node, traversal_state}
      end)

    result
  end

  defp count_siblings(nodes) do
    Enum.reduce(nodes, {0, %{}}, fn
      {tag, _, _}, {total, by_tag} ->
        {total + 1, Map.update(by_tag, tag, 1, &(&1 + 1))}

      _non_element, acc ->
        acc
    end)
  end

  defp initial_traversal_state,
    do: %{previous_siblings: [], child_position: 0, of_type_position: %{}}

  defp next_traversal_state(state, tag) do
    %{
      state
      | child_position: state.child_position + 1,
        of_type_position: Map.update(state.of_type_position, tag, 1, &(&1 + 1))
    }
  end

  defp push_previous_sibling(state, context),
    do: %{state | previous_siblings: [context | state.previous_siblings]}

  defp element_context({tag, attrs, children}, traversal_state, ancestors, total, by_tag) do
    %{
      tag: tag,
      attrs: attrs,
      previous_siblings: traversal_state.previous_siblings,
      child_position: traversal_state.child_position,
      total_siblings: total,
      of_type_position: Map.fetch!(traversal_state.of_type_position, tag),
      total_of_type: Map.fetch!(by_tag, tag),
      empty?: children == [],
      root?: ancestors == []
    }
  end

  # Items may appear more than once if their selector contains comma-separated
  # groups that produce different match items; callers should expect
  # duplicates.
  defp applicable_selector_items(selector_items_table, tag, attrs) do
    selector_items_table.universal
    |> prepend_selector_items(selector_items_table.by_tag, tag)
    |> prepend_selector_items(selector_items_table.by_id, get_attr(attrs, "id"))
    |> prepend_class_selector_items(selector_items_table.by_class, attrs)
  end

  defp prepend_selector_items(acc, bucket, key), do: Map.get(bucket, key, []) ++ acc

  defp prepend_class_selector_items(acc, by_class, attrs) do
    case get_attr(attrs, "class") do
      nil ->
        acc

      classes_str ->
        classes_str
        |> :binary.split(" ", [:global])
        |> Enum.reduce(acc, &prepend_selector_items(&2, by_class, &1))
    end
  end

  # The lookup table buckets selector items by tag, id, and class, so matches
  # are gathered per bucket rather than in the order the items were given in.
  # Consumers rely on that order, e.g. the CSS cascade resolves declarations of
  # equal specificity by source order, so it's restored here.
  #
  # A selector item is registered once per selector group, so it can be matched
  # more than once. Duplicates are consecutive after the sort and dropped.
  defp restore_source_order([]), do: []
  defp restore_source_order([_selector_item] = selector_items), do: selector_items

  defp restore_source_order(selector_items) do
    selector_items
    |> Enum.sort_by(& &1.source_index)
    |> Enum.dedup_by(& &1.source_index)
  end

  defp matches_selector_group?(_context, [], _ancestors), do: false

  defp matches_selector_group?(context, [step | rest], ancestors) do
    match_segment?(context, step) and
      match_remaining_selector_steps?(rest, context, ancestors)
  end

  defp match_segment?(%{tag: tag, attrs: attrs} = context, selector_segment) do
    match_tag?(tag, selector_segment.tag) and
      match_id?(attrs, selector_segment.id) and
      match_classes?(attrs, selector_segment.class_patterns) and
      match_attributes?(attrs, selector_segment.attrs) and
      match_pseudos?(context, selector_segment.pseudos)
  end

  defp match_tag?(_tag, nil), do: true
  defp match_tag?(_tag, "*"), do: true
  defp match_tag?(tag, tag), do: true
  defp match_tag?(_tag, _expected_tag), do: false

  defp match_id?(_attrs, nil), do: true
  defp match_id?(attrs, expected_id), do: get_attr(attrs, "id") == expected_id

  defp get_attr(attrs, name) do
    case List.keyfind(attrs, name, 0) do
      {_, value} -> value
      nil -> nil
    end
  end

  defp match_classes?(_attrs, []), do: true

  defp match_classes?(attrs, class_patterns) do
    case List.keyfind(attrs, "class", 0) do
      nil ->
        false

      {_, classes} ->
        padded = <<" ", classes::binary, " ">>
        Enum.all?(class_patterns, &(:binary.match(padded, &1) != :nomatch))
    end
  end

  defp match_attributes?(_attrs, []), do: true

  defp match_attributes?(attrs, expected_attrs) do
    Enum.all?(expected_attrs, fn
      {name, value} -> get_attr(attrs, name) == value
      name -> List.keymember?(attrs, name, 0)
    end)
  end

  defp match_pseudos?(_context, []), do: true

  defp match_pseudos?(context, pseudos) do
    Enum.all?(pseudos, &match_pseudo?(context, &1))
  end

  defp match_pseudo?(_context, %{kind: :pseudo_element}), do: false

  defp match_pseudo?(context, %{kind: :pseudo_class, name: name} = pseudo),
    do: match_pseudo_class?(name, pseudo, context)

  defp match_pseudo_class?("first-child", _, ctx), do: ctx.child_position == 1
  defp match_pseudo_class?("last-child", _, ctx), do: ctx.child_position == ctx.total_siblings
  defp match_pseudo_class?("only-child", _, ctx), do: ctx.total_siblings == 1
  defp match_pseudo_class?("first-of-type", _, ctx), do: ctx.of_type_position == 1
  defp match_pseudo_class?("last-of-type", _, ctx), do: ctx.of_type_position == ctx.total_of_type
  defp match_pseudo_class?("only-of-type", _, ctx), do: ctx.total_of_type == 1
  defp match_pseudo_class?("empty", _, ctx), do: ctx.empty?
  defp match_pseudo_class?("root", _, ctx), do: ctx.root?

  defp match_pseudo_class?("nth-child", pseudo, ctx),
    do: matches_nth?(ctx.child_position, pseudo.nth)

  defp match_pseudo_class?("nth-of-type", pseudo, ctx),
    do: matches_nth?(ctx.of_type_position, pseudo.nth)

  defp match_pseudo_class?("nth-last-child", pseudo, ctx),
    do: matches_nth?(ctx.total_siblings - ctx.child_position + 1, pseudo.nth)

  defp match_pseudo_class?("nth-last-of-type", pseudo, ctx),
    do: matches_nth?(ctx.total_of_type - ctx.of_type_position + 1, pseudo.nth)

  defp match_pseudo_class?(_name, _pseudo, _ctx), do: false

  defp matches_nth?(position, {0, b}), do: position == b

  defp matches_nth?(position, {a, b}) do
    diff = position - b

    rem(diff, a) == 0 and div(diff, a) >= 0
  end

  # Any pseudos that cannot be parsed are treated as invalid and never match.
  defp matches_nth?(_position, :invalid), do: false

  defp match_remaining_selector_steps?([], _context, _ancestors), do: true

  defp match_remaining_selector_steps?([step | _rest] = steps, context, ancestors) do
    case step.combinator do
      :descendant ->
        match_descendant_selector_steps?(steps, ancestors)

      :child ->
        match_child_selector_steps?(steps, ancestors)

      :adjacent ->
        match_adjacent_selector_steps?(steps, context, ancestors)

      :sibling ->
        match_sibling_selector_steps?(steps, context, ancestors)

      :column ->
        Logger.debug(fn -> "Column combinator (||) is not implemented. Ignoring." end)

        false
    end
  end

  defp match_descendant_selector_steps?(_steps, []), do: false

  defp match_descendant_selector_steps?(steps, [candidate | ancestors]) do
    matches_selector_group?(candidate, steps, ancestors) or
      match_descendant_selector_steps?(steps, ancestors)
  end

  defp match_child_selector_steps?(_steps, []), do: false

  defp match_child_selector_steps?(steps, [candidate | ancestors]) do
    matches_selector_group?(candidate, steps, ancestors)
  end

  defp match_adjacent_selector_steps?(_steps, %{previous_siblings: []}, _ancestors), do: false

  defp match_adjacent_selector_steps?(steps, %{previous_siblings: [candidate | _]}, ancestors) do
    matches_selector_group?(candidate, steps, ancestors)
  end

  defp match_sibling_selector_steps?(steps, %{previous_siblings: previous_siblings}, ancestors) do
    Enum.any?(previous_siblings, &matches_selector_group?(&1, steps, ancestors))
  end

  @doc """
  Returns a list of HTML elements matching the selector.

  ## Examples

      iex> Premailex.DOM.all([{"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}], "h1")
      [{"h1", [], ["Title"]}]

      iex> Premailex.DOM.all({"div", [], [{"p", [], ["a"]}, {"p", [], ["b"]}]}, "p")
      [{"p", [], ["a"]}, {"p", [], ["b"]}]
  """
  @spec all(Premailex.html_tree() | Premailex.html_element(), selector()) ::
          [Premailex.html_element()]
  def all(tree, selector) when is_list(tree) do
    compiled_selector_groups = compile_selector_groups(selector)

    traverse_select(tree, compiled_selector_groups, [], fn
      node, true, descendants -> [node | descendants]
      _node, false, descendants -> descendants
    end)
  end

  def all({_, _, _} = element, selector), do: all([element], selector)

  defp traverse_select(nodes, compiled_selector_groups, ancestors, fun) do
    {total, by_tag} = count_siblings(nodes)

    {results, _traversal_state} =
      Enum.flat_map_reduce(nodes, initial_traversal_state(), fn
        {tag, _attrs, children} = element, traversal_state ->
          traversal_state = next_traversal_state(traversal_state, tag)
          context = element_context(element, traversal_state, ancestors, total, by_tag)

          matched? =
            Enum.any?(compiled_selector_groups, &matches_selector_group?(context, &1, ancestors))

          descendants =
            traverse_select(children, compiled_selector_groups, [context | ancestors], fun)

          {fun.(element, matched?, descendants), push_previous_sibling(traversal_state, context)}

        node, traversal_state ->
          {fun.(node, false, []), traversal_state}
      end)

    results
  end

  @doc """
  Filters HTML elements matching the selector from the tree, collapsing
  redundant whitespace text nodes left behind.

  Always returns a `t:Premailex.html_tree/0`, even when a single element is
  passed in; if that element matches the selector, the result is `[]`.

  ## Examples

      iex> Premailex.DOM.reject([{"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}], "h1")
      [{"html", [], [{"head", [], []}, {"body", [], []}]}]

      iex> Premailex.DOM.reject({"div", [], [{"p", [], ["a"]}, {"h1", [], ["b"]}]}, "h1")
      [{"div", [], [{"p", [], ["a"]}]}]

      iex> Premailex.DOM.reject({"h1", [], ["Title"]}, "h1")
      []
  """
  @spec reject(Premailex.html_tree() | Premailex.html_element(), selector()) ::
          Premailex.html_tree()
  def reject(tree, selector) when is_list(tree) do
    compiled_selector_groups = compile_selector_groups(selector)

    traverse_select(tree, compiled_selector_groups, [], fn
      _node, true, _ -> []
      {tag, attrs, _}, false, children -> [{tag, attrs, collapse_whitespace(children)}]
      node, false, _ -> [node]
    end)
  end

  def reject({_, _, _} = element, selector), do: reject([element], selector)

  defp collapse_whitespace(children) do
    Enum.dedup_by(children, fn
      text when is_binary(text) -> (String.trim(text) == "" && :whitespace) || text
      other -> other
    end)
  end

  @doc """
  Extracts and concatenates the text content from HTML elements.

  ## Examples

      iex> Premailex.DOM.text_content([{"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Title"]}]}]}])
      "Title"
  """
  @spec text_content(Premailex.html_tree() | Premailex.html_element()) :: String.t()
  def text_content(tree) when is_list(tree), do: Enum.map_join(tree, &text_content/1)
  def text_content(text) when is_binary(text), do: text
  def text_content({:comment, _}), do: ""
  def text_content({_name, _attrs, children}), do: text_content(children)
end
