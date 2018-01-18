defmodule Premailex.UtilTest do
  use ExUnit.Case
  doctest Premailex.Util

  test "traverse_until_first/3 deep nested" do
    div_children = [{"p", [], ["Paragraph"]}, {"p", [], ["Paragraph"]}]
    html = {"div", [], [{"div", [], div_children}, {"div", [], div_children}]}
    needle = {"p", [], ["Paragraph"]}

    result = Premailex.Util.traverse_until_first(html, needle, fn {name, attrs, _children} -> {name, attrs, ["Updated"]} end)

    assert result == {"div", [], [{"div", [], [{"p", [], ["Updated"]}, {"p", [], ["Paragraph"]}]}, {"div", [], [{"p", [], ["Paragraph"]}, {"p", [], ["Paragraph"]}]}]}
  end
end
