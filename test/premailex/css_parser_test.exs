defmodule Premailex.CSSParserTest do
  use ExUnit.Case
  doctest Premailex.CSSParser

  @input """
body, table {background-color:#ffffff;color:#000000;}
div p > a:hover {color:#000000 !important;text-decoration:underline}
"""

  @parsed [%{rules: [%{directive: "background-color", value: "#ffffff", important?: false},
                     %{directive: "color", value: "#000000", important?: false}],
             selector: "body",
             specificity: 1},
           %{rules: [%{directive: "background-color", value: "#ffffff", important?: false},
                     %{directive: "color", value: "#000000", important?: false}],
             selector: "table",
             specificity: 1},
           %{rules: [%{directive: "color", value: "#000000 !important", important?: true},
                     %{directive: "text-decoration", value: "underline", important?: false}],
             selector: "div p > a:hover",
             specificity: 4}]

  test "parse/1" do
    assert Premailex.CSSParser.parse(@input) == @parsed
  end
end
