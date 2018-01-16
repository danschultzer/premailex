defmodule Premailex.Util do
  @moduledoc """
  Module that contains utility functions.
  """

  @type html_tree :: tuple | list
  @type needle :: binary | tuple | list

  @doc """
  Traverses tree searching for needle, and will call provided function on
  any occurances.

  If the function returns {:halt, any}, traverse will stop, and result will
  be {:halt, html_tree}.

  ## Examples

      iex> Premailex.Util.traverse({"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Second paragraph"]}]}, "p", fn {name, attrs, _children} -> {name, attrs, ["Updated"]} end)
      {"div", [], [{"p", [], ["Updated"]}, {"p", [], ["Updated"]}]}

      iex> Premailex.Util.traverse({"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Second paragraph"]}]}, {"p", [], ["Second paragraph"]}, fn {name, attrs, _children} -> {name, attrs, ["Updated"]} end)
      {"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Updated"]}]}
  """
  @spec traverse(html_tree, needle, function) :: html_tree | {:halt, html_tree}
  def traverse(html, needles, fun) when is_list(needles),
    do: Enum.reduce(needles, html, &traverse(&2, &1, fun))
  def traverse(children, needle, fun) when is_list(children) do
    children
    |> Enum.map_reduce(:ok, &maybe_traverse({&1, needle, fun}, &2))
    |> case do
        {children, :halt} -> {:halt, children}
        {children, :ok}   -> children
      end
  end
  def traverse(text, _, _) when is_binary(text),
    do: text
  def traverse({name, attrs, children} = element, needle, fun) do
    cond do
      needle == name    -> fun.(element)
      needle == element -> fun.(element)
      true              -> handle_traversed({name, attrs, children}, needle, fun)
    end
  end
  def traverse({:comment, _}, _, _),
    do: ""
  def traverse(element, _, _),
    do: element

  defp maybe_traverse({element, needle, fun}, :ok) do
    case traverse(element, needle, fun) do
      {:halt, children} -> {children, :halt}
      children          -> {children, :ok}
    end
  end
  defp maybe_traverse({element, _needle, _fun}, :halt),
    do: {element, :halt}

  defp handle_traversed({name, attrs, children}, needle, fun) do
    case traverse(children, needle, fun) do
      {:halt, children} -> {:halt, {name, attrs, children}}
      children          -> {name, attrs, children}
    end
  end

  @doc """
  Traverse all trees in array searching for needle, and will call function with
  element and number times needle has been found so far.

  ## Examples

      iex> Premailex.Util.traverse_reduce([{"p", [], ["First paragraph"]}, {"p", [], ["Second paragraph"]}], "p", fn({name, attrs, _children}, acc) -> {name, attrs, ["Updated " <> to_string(acc)]} end)
      {[{"p", [], ["Updated 0"]}, {"p", [], ["Updated 1"]}], 2}
  """
  @spec traverse_reduce(list, needle, function) :: {html_tree, integer}
  def traverse_reduce(children, needle, fun) when is_list(children),
    do: Enum.map_reduce(children, 0, &{traverse(&1, needle, fn element -> fun.(element, &2) end), &2 + 1})

  @doc """
  Traverses tree until first match for needle.

  ## Examples

      iex> Premailex.Util.traverse_until_first({"div", [], [{"p", [], ["First paragraph"]}, {"p", [], ["Second paragraph"]}]}, "p", fn {name, attrs, _children} -> {name, attrs, ["Updated"]} end)
      {"div", [], [{"p", [], ["Updated"]}, {"p", [], ["Second paragraph"]}]}
  """
  @spec traverse_until_first(html_tree, needle, function) :: html_tree
  def traverse_until_first(html, needle, fun) do
    case traverse(html, needle, &{:halt, fun.(&1)}) do
      {:halt, html} -> html
      html          -> html
    end
  end
end
