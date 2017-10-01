defmodule Premailex.Util do
  @moduledoc false

  def traverse(html, needles, fun) when is_list(needles),
    do: Enum.reduce(needles, html, &traverse(&2, &1, fun))
  def traverse(children, needle, fun) when is_list(children),
    do: Enum.map(children, &traverse(&1, needle, fun))
  def traverse(text, _, _) when is_binary(text),
    do: text
  def traverse({name, attrs, children} = element, needle, fun) do
    cond do
      needle == name    -> fun.(element)
      needle == element -> fun.(element)
      true              -> {name, attrs, traverse(children, needle, fun)}
    end
  end
  def traverse({:comment, _}, _, _),
    do: ""
  def traverse(element, _, _),
    do: element

  def traverse_reduce(children, needle, fun) when is_list(children),
    do: Enum.map_reduce(children, 0, &{traverse(&1, needle, fn element -> fun.(element, &2) end), &2 + 1})
end
