defmodule Premailex.CSSParserTest do
  use ExUnit.Case
  doctest Premailex.CSSParser

  @input """
  body, table {/* text-decoration:underline */background-color:#ffffff;background-image:url('http://example.com/image.png');color:#000000;}
  div p > a:hover {color:#000000 !important;text-decoration:underline}
  /*div {
    padding:10px
  }*/
  @media screen and (max-width: 600px) {
    body {
      width: auto;
    }
  }
  @font-face {
    font-family: "Open Sans";
    src: url("/fonts/OpenSans-Regular-webfont.woff2") format("woff2"),
         url("/fonts/OpenSans-Regular-webfont.woff") format("woff");
  }
  .with\\,escaped\\,commas {}
  .with-empty-selector, {}
  """

  @parsed [
    %{
      rules: [
        %{directive: "background-color", value: "#ffffff", important?: false},
        %{
          directive: "background-image",
          value: "url('http://example.com/image.png')",
          important?: false
        },
        %{directive: "color", value: "#000000", important?: false}
      ],
      selector: "body",
      specificity: 1
    },
    %{
      rules: [
        %{directive: "background-color", value: "#ffffff", important?: false},
        %{
          directive: "background-image",
          value: "url('http://example.com/image.png')",
          important?: false
        },
        %{directive: "color", value: "#000000", important?: false}
      ],
      selector: "table",
      specificity: 1
    },
    %{
      rules: [
        %{directive: "color", value: "#000000 !important", important?: true},
        %{directive: "text-decoration", value: "underline", important?: false}
      ],
      selector: "div p > a:hover",
      specificity: 4
    },
    %{
      rules: [],
      selector: ".with\\,escaped\\,commas",
      specificity: 1
    },
    %{
      rules: [],
      selector: ".with-empty-selector",
      specificity: 1
    }
  ]

  test "parse/1" do
    assert Premailex.CSSParser.parse(@input) == @parsed
  end

  describe "split_selector_groups/1" do
    test "with empty selector" do
      assert Premailex.CSSParser.split_selector_groups("") == []
    end

    test "with commas selector" do
      assert Premailex.CSSParser.split_selector_groups(",,,,") == []
    end

    test "with whitespace selector" do
      assert Premailex.CSSParser.split_selector_groups("\t") == []
      assert Premailex.CSSParser.split_selector_groups("    ") == []
    end

    test "with attribute selector with quoted value" do
      assert Premailex.CSSParser.split_selector_groups(~s([data='a,b,c'] + [data="x,y"], .bar)) ==
               [~s([data='a,b,c'] + [data="x,y"]), ".bar"]
    end

    test "with attribute selector with quoted value containing quote" do
      assert Premailex.CSSParser.split_selector_groups(~s([data='a,"b,c'] + [data="x,'y"], .bar)) ==
               [~s([data='a,"b,c'] + [data="x,'y"]), ".bar"]
    end

    test "with attribute selector with quoted value with escaped quotes" do
      assert Premailex.CSSParser.split_selector_groups(
               ~s([data='a,\\'b,c'] + [data="x,\\"y"], .bar)
             ) == [
               ~s([data='a,\\'b,c'] + [data="x,\\"y"]),
               ".bar"
             ]
    end

    test "with attribute selector with malformed quoted value" do
      assert Premailex.CSSParser.split_selector_groups(~s([data="a,b,c], .foo)) == [
               ~s([data="a,b,c], .foo)
             ]

      assert Premailex.CSSParser.split_selector_groups(~s([data=a,b,c"], .foo)) == [
               ~s([data=a,b,c"], .foo)
             ]
    end

    test "with attribute selector with quoted value with newlines" do
      assert Premailex.CSSParser.split_selector_groups("[data=\"line1\nline2\"], .foo") == [
               "[data=\"line1\nline2\"]",
               ".foo"
             ]
    end

    test "with comma separated selectors" do
      assert Premailex.CSSParser.split_selector_groups("div  ,  .foo,\t.bar") == [
               "div",
               ".foo",
               ".bar"
             ]
    end

    test "with comma separated selectors with newlines" do
      assert Premailex.CSSParser.split_selector_groups("""
               div ,
             .foo,
             .bar
             """) == ["div", ".foo", ".bar"]
    end

    test "with comma separated selectors with consecutive commas" do
      assert Premailex.CSSParser.split_selector_groups(",.foo,,,.bar,,") == [".foo", ".bar"]
    end

    test "with comma separated selectors with escaped commas" do
      assert Premailex.CSSParser.split_selector_groups(".with\\,escaped\\,commas") == [
               ~s(.with\\,escaped\\,commas)
             ]
    end

    test "with attribute selector" do
      assert Premailex.CSSParser.split_selector_groups("span[data-y], .foo") ==
               ["span[data-y]", ".foo"]
    end

    test "with attribute selector with brackets" do
      assert Premailex.CSSParser.split_selector_groups("[[data]], .foo") == [
               "[[data]]",
               ".foo"
             ]

      assert Premailex.CSSParser.split_selector_groups(~s([href="a]b"], [data-x="a[b"])) ==
               [~s([href="a]b"]), ~s([data-x="a[b"])]
    end

    test "with malformed attribute selector" do
      assert Premailex.CSSParser.split_selector_groups("[data, .foo") == ["[data, .foo"]

      assert Premailex.CSSParser.split_selector_groups("data], .foo") == [
               "data]",
               ".foo"
             ]
    end

    test "with attribute selector with newlines" do
      assert Premailex.CSSParser.split_selector_groups("[data\nattr], .foo") == [
               "[data\nattr]",
               ".foo"
             ]
    end

    test "with functional pseudo-class selector" do
      assert Premailex.CSSParser.split_selector_groups("div:not(.foo, .bar), .baz") == [
               "div:not(.foo, .bar)",
               ".baz"
             ]
    end

    test "with nested functional pseudo-class selector" do
      assert Premailex.CSSParser.split_selector_groups("div:is(:not(.foo, .bar), .baz), .qux") ==
               [
                 "div:is(:not(.foo, .bar), .baz)",
                 ".qux"
               ]
    end

    test "with malformed functional pseudo-class selector" do
      assert Premailex.CSSParser.split_selector_groups("div:not(.foo, .bar, .baz") == [
               "div:not(.foo, .bar, .baz"
             ]

      assert Premailex.CSSParser.split_selector_groups("div:not.foo, .bar), .baz)") == [
               "div:not.foo",
               ".bar)",
               ".baz)"
             ]
    end

    test "with functional pseudo-class selector with newlines" do
      assert Premailex.CSSParser.split_selector_groups("div:not(\n.foo, .bar\n), .baz") == [
               "div:not(\n.foo, .bar\n)",
               ".baz"
             ]
    end
  end

  describe "parse_rules/1" do
    test "with empty rule" do
      assert Premailex.CSSParser.parse_rules("") == []
    end

    test "with semicolon rule" do
      assert Premailex.CSSParser.parse_rules(";;;;") == []
    end

    test "with whitespace rule" do
      assert Premailex.CSSParser.parse_rules("\t") == []
      assert Premailex.CSSParser.parse_rules("    ") == []
    end

    test "with rule" do
      assert Premailex.CSSParser.parse_rules("color: red;background-color: blue;") ==
               [
                 %{directive: "color", value: "red", important?: false},
                 %{directive: "background-color", value: "blue", important?: false}
               ]
    end

    test "with rule with !important value" do
      assert Premailex.CSSParser.parse_rules("""
             color: red !important ;
             background-color: blue !IMPORTANT;
             text-decoration: underline !important;
             width: 100px!important
             """) ==
               [
                 %{directive: "color", value: "red !important", important?: true},
                 %{directive: "background-color", value: "blue !IMPORTANT", important?: true},
                 %{directive: "text-decoration", value: "underline !important", important?: true},
                 %{directive: "width", value: "100px!important", important?: true}
               ]
    end

    test "with rule with malformed !important" do
      assert Premailex.CSSParser.parse_rules(
               "color: !important red;background: blue !important\""
             ) ==
               [
                 %{directive: "color", value: "!important red", important?: false},
                 %{directive: "background", value: "blue !important\"", important?: false}
               ]
    end

    test "with rules with newline" do
      assert Premailex.CSSParser.parse_rules("""
             color: red;
             background:
             blue;
             """) ==
               [
                 %{directive: "color", value: "red", important?: false},
                 %{directive: "background", value: "blue", important?: false}
               ]
    end

    test "with rules with varying whitespace" do
      assert Premailex.CSSParser.parse_rules("""
             color  :  red  ;
             background:\tblue\t;
             """) ==
               [
                 %{directive: "color", value: "red", important?: false},
                 %{directive: "background", value: "blue", important?: false}
               ]
    end

    test "with rule without trailing semicolon" do
      assert Premailex.CSSParser.parse_rules("color: red") ==
               [
                 %{directive: "color", value: "red", important?: false}
               ]
    end

    test "with malformed rule" do
      assert Premailex.CSSParser.parse_rules("color red background: blue") ==
               [
                 %{directive: "color red background", value: "blue", important?: false}
               ]
    end
  end

  describe "calculate_specificity/1 edge cases" do
    test "complex selector chain" do
      css = "div#id.class1.class2[attr1][attr2]:hover > p { color: red; }"
      parsed = Premailex.CSSParser.parse(css)
      [rule_set] = parsed
      # 1 id + 2 classes + 2 attributes + 1 pseudo-class + 2 elements = 8
      assert rule_set.specificity == 8
    end

    test "pseudo-element" do
      css = "div::before { content: 'test'; }"
      parsed = Premailex.CSSParser.parse(css)
      [rule_set] = parsed
      # 1 element + 1 pseudo-element = 2
      assert rule_set.specificity == 2
    end

    test "only pseudo-classes" do
      css = ":hover:focus:active { color: blue; }"
      parsed = Premailex.CSSParser.parse(css)
      [rule_set] = parsed
      # 3 pseudo-classes
      assert rule_set.specificity == 3
    end
  end

  describe "full parse/1 edge cases" do
    test "selectors with attribute containing comma and space" do
      css = "div[data-x=\"a, b\"] { color: red; }"
      parsed = Premailex.CSSParser.parse(css)
      assert length(parsed) == 1
      assert Enum.find(parsed, fn r -> r.selector == "div[data-x=\"a, b\"]" end)
    end

    test "multiple selectors with complex nesting" do
      css = """
        a[href="http://example.com?x=1,y=2"],
        b:not(div),
        c > d[data='test'] { color: blue; }
      """

      parsed = Premailex.CSSParser.parse(css)
      assert length(parsed) == 3
      assert Enum.find(parsed, fn r -> String.contains?(r.selector, "href=") end)
      assert Enum.find(parsed, fn r -> String.contains?(r.selector, ":not(div)") end)
    end

    test "empty selector block" do
      css = "div { }"
      parsed = Premailex.CSSParser.parse(css)
      assert length(parsed) == 1
      assert Enum.find(parsed, fn r -> r.rules == [] end)
    end

    test "rule without value" do
      css = "div { color: ; }"
      parsed = Premailex.CSSParser.parse(css)
      assert length(parsed) == 1
      # Should still parse, even if value is empty
    end
  end
end
