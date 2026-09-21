defmodule Premailex.DOMTest do
  use ExUnit.Case
  doctest Premailex.DOM

  import ExUnit.CaptureLog

  alias Premailex.{CSSParser, DOM, HTMLParser.Xmerl}

  describe "replace_all_matches/3" do
    setup do
      tree =
        Premailex.parse("""
        <div>
          <!-- Comment -->
          <p>First paragraph</p>
          <p>Second paragraph</p>
        </div>\
        """)

      {:ok, tree: tree}
    end

    test "with tag name needle", %{tree: tree} do
      assert DOM.replace_all_matches(tree, "p", fn {name, attrs, _children} ->
               {name, attrs, ["Updated"]}
             end) == [
               {"div", [],
                [
                  "\n  ",
                  {:comment, " Comment "},
                  "\n  ",
                  {"p", [], ["Updated"]},
                  "\n  ",
                  {"p", [], ["Updated"]},
                  "\n"
                ]}
             ]
    end

    test "with element needle", %{tree: tree} do
      assert DOM.replace_all_matches(tree, {"p", [], ["Second paragraph"]}, fn {name, attrs,
                                                                                _children} ->
               {name, attrs, ["Updated"]}
             end) == [
               {"div", [],
                [
                  "\n  ",
                  {:comment, " Comment "},
                  "\n  ",
                  {"p", [], ["First paragraph"]},
                  "\n  ",
                  {"p", [], ["Updated"]},
                  "\n"
                ]}
             ]
    end

    test "with :comment needle", %{tree: tree} do
      assert DOM.replace_all_matches(tree, :comment, fn {:comment, _comment} ->
               {:comment, "Updated"}
             end) == [
               {"div", [],
                [
                  "\n  ",
                  {:comment, "Updated"},
                  "\n  ",
                  {"p", [], ["First paragraph"]},
                  "\n  ",
                  {"p", [], ["Second paragraph"]},
                  "\n"
                ]}
             ]
    end

    test "with list of needles", %{tree: tree} do
      assert DOM.replace_all_matches(tree, ["p", :comment], fn _any ->
               "Updated"
             end) == [
               {"div", [], ["\n  ", "Updated", "\n  ", "Updated", "\n  ", "Updated", "\n"]}
             ]
    end
  end

  describe "replace_first_match/3" do
    setup do
      tree =
        Premailex.parse("""
        <div>
          <!-- Comment 1 -->
          <!-- Comment 2 -->
          <p>Paragraph</p>
          <p>Paragraph</p>
        </div>\
        """)

      {:ok, tree: tree}
    end

    test "with tag name needle", %{tree: tree} do
      assert DOM.replace_first_match(tree, "p", fn {name, attrs, _children} ->
               {name, attrs, ["Updated"]}
             end) == [
               {"div", [],
                [
                  "\n  ",
                  {:comment, " Comment 1 "},
                  "\n  ",
                  {:comment, " Comment 2 "},
                  "\n  ",
                  {"p", [], ["Updated"]},
                  "\n  ",
                  {"p", [], ["Paragraph"]},
                  "\n"
                ]}
             ]
    end

    test "with element needle", %{tree: tree} do
      assert DOM.replace_first_match(tree, {"p", [], ["Paragraph"]}, fn _ ->
               {"p", [], ["Updated"]}
             end) == [
               {"div", [],
                [
                  "\n  ",
                  {:comment, " Comment 1 "},
                  "\n  ",
                  {:comment, " Comment 2 "},
                  "\n  ",
                  {"p", [], ["Updated"]},
                  "\n  ",
                  {"p", [], ["Paragraph"]},
                  "\n"
                ]}
             ]
    end

    test "with :comment needle", %{tree: tree} do
      assert DOM.replace_first_match(tree, :comment, fn {:comment, _comment} ->
               {:comment, "Updated"}
             end) == [
               {"div", [],
                [
                  "\n  ",
                  {:comment, "Updated"},
                  "\n  ",
                  {:comment, " Comment 2 "},
                  "\n  ",
                  {"p", [], ["Paragraph"]},
                  "\n  ",
                  {"p", [], ["Paragraph"]},
                  "\n"
                ]}
             ]
    end

    test "with no match returns tree unchanged", %{tree: tree} do
      assert DOM.replace_first_match(tree, "nonexistent", fn _ -> :replaced end) == tree
    end
  end

  describe "traverse_with_matching_items/3" do
    setup do
      tree =
        Premailex.parse("""
        <section id="main">
          <!--hidden-->
          <div class="container">
            <p class="intro featured" data-kind="primary" data-x="1">First</p>
            <p>Second</p>
            <a href="/">Link</a>
            <a href="/go" class="cta">Link</a>
          </div>
          <p>Outside div</p>
        </section>
        """)

      {:ok, tree: tree}
    end

    test "with tag selector", %{tree: tree} do
      assert [
               {"p", _, ["First"]},
               {"p", _, ["Second"]},
               {"p", _, ["Outside div"]}
             ] = list_matched_elements(tree, "p { x: 1; }")
    end

    test "with universal tag selector", %{tree: tree} do
      assert [
               {"section", _, _},
               {"div", _, _},
               {"p", _, ["First"]},
               {"p", _, ["Second"]},
               {"a", _, ["Link"]},
               {"a", _, ["Link"]},
               {"p", _, ["Outside div"]}
             ] = list_matched_elements(tree, "* { x: 1; }")
    end

    test "with id selector", %{tree: tree} do
      assert [{"section", _, _}] = list_matched_elements(tree, "#main { x: 1; }")
    end

    test "with class selector", %{tree: tree} do
      assert [{"a", %{"class" => "cta"}, ["Link"]}] =
               list_matched_elements(tree, ".cta { x: 1; }")
    end

    test "with multi-class selector", %{tree: tree} do
      assert [{"p", %{"class" => "intro featured"}, ["First"]}] =
               list_matched_elements(tree, ".intro.featured { x: 1; }")
    end

    test "with attribute selector", %{tree: tree} do
      assert [{"a", %{"href" => "/"}, ["Link"]}, {"a", %{"href" => "/go"}, ["Link"]}] =
               list_matched_elements(tree, "[href] { x: 1; }")
    end

    test "with attribute equality selector", %{tree: tree} do
      assert [{"a", %{"href" => "/go"}, ["Link"]}] =
               list_matched_elements(tree, ~s(a[href="/go"] { x: 1; }))
    end

    test "with pseudo-element selector", %{tree: tree} do
      assert list_matched_elements(tree, "p::before { x: 1; }") == []
    end

    test "with pseudo-class selector with :last-child", %{tree: tree} do
      assert [
               {"section", _, _},
               {"a", %{"class" => "cta"}, ["Link"]},
               {"p", _, ["Outside div"]}
             ] = list_matched_elements(tree, ":last-child { x: 1; }")
    end

    test "with pseudo-class selector with :first-of-type", %{tree: tree} do
      assert [
               {"p", _, ["First"]},
               {"p", _, ["Outside div"]}
             ] = list_matched_elements(tree, "p:first-of-type { x: 1; }")
    end

    test "with pseudo-class selector with :empty" do
      tree = Premailex.parse(~s(<div><p></p><p>x</p></div>))

      assert [{"p", _, []}] = list_matched_elements(tree, ":empty { x: 1; }")
    end

    test "with pseudo-class selector with :root" do
      tree = Premailex.parse(~s(<p>a</p><div>b</div>))

      assert [{"p", _, ["a"]}, {"div", _, ["b"]}] =
               list_matched_elements(tree, ":root { x: 1; }")
    end

    test "with pseudo-class selector with :nth-child", %{tree: tree} do
      assert [
               {"p", _, ["Second"]},
               {"a", %{"href" => "/go"}, _},
               {"p", _, ["Outside div"]}
             ] = list_matched_elements(tree, ":nth-child(2n) { x: 1; }")
    end

    test "with descendant combinator selector", %{tree: tree} do
      assert [
               {"p", _, ["First"]},
               {"p", _, ["Second"]}
             ] = list_matched_elements(tree, "div p { x: 1; }")
    end

    test "with child combinator selector", %{tree: tree} do
      assert [{"p", _, ["Outside div"]}] = list_matched_elements(tree, "section > p { x: 1; }")
    end

    test "with adjacent sibling combinator selector", %{tree: tree} do
      assert [{"p", _, ["Second"]}] = list_matched_elements(tree, "p.intro + p { x: 1; }")
    end

    test "with general sibling combinator selector", %{tree: tree} do
      assert [{"a", %{"href" => "/"}, ["Link"]}, {"a", %{"href" => "/go"}, ["Link"]}] =
               list_matched_elements(tree, "p ~ [href] { x: 1; }")
    end

    test "with multiple selector groups", %{tree: tree} do
      assert [
               {"p", _, ["First"]},
               {"a", _, ["Link"]}
             ] = list_matched_elements(tree, "p.intro, a.cta { x: 1; }")
    end

    test "with multiple selector groups that match the same element", %{
      tree: tree
    } do
      rules = CSSParser.parse("p, .intro { x: 1; }")

      result =
        DOM.traverse_with_matching_items(tree, rules, fn {tag, attrs, children}, matched_rules ->
          {tag, [{"data-count", Integer.to_string(length(matched_rules))} | attrs], children}
        end)

      assert [{"p", [{"data-count", "2"} | _], ["First"]}] = DOM.all(result, ".intro")
      assert [{"p", [{"data-count", "1"} | _], ["Outside div"]}] = DOM.all(result, "section > p")
    end

    test "with multiple selector items that match the same element", %{tree: tree} do
      rules = CSSParser.parse(".intro { x: 1; } .featured { x: 2; } [data-kind] { x: 3; }")

      result =
        DOM.traverse_with_matching_items(tree, rules, fn {tag, attrs, children}, matched_rules ->
          selectors = Enum.map(matched_rules, & &1.selector)

          {tag, [{"data-selectors", Enum.join(selectors, ",")} | attrs], children}
        end)

      assert [{"p", [{"data-selectors", ".intro,.featured,[data-kind]"} | _], [_]}] =
               DOM.all(result, ".intro.featured")

      reversed_rules =
        CSSParser.parse(".featured { x: 1; } [data-kind] { x: 2; } .intro { x: 3; }")

      reversed_result =
        DOM.traverse_with_matching_items(tree, reversed_rules, fn {tag, attrs, children},
                                                                  matched_rules ->
          selectors = Enum.map(matched_rules, & &1.selector)

          {tag, [{"data-selectors", Enum.join(selectors, ",")} | attrs], children}
        end)

      assert [{"p", [{"data-selectors", ".featured,[data-kind],.intro"} | _], [_]}] =
               DOM.all(reversed_result, ".intro.featured")
    end

    test "with no selector items", %{tree: tree} do
      assert DOM.traverse_with_matching_items(tree, [], fn _element, _matched_rules ->
               raise "should not be called"
             end) == tree
    end

    test "with no matches", %{tree: tree} do
      rules = CSSParser.parse(".nonexistent { x: 1; }")

      assert DOM.traverse_with_matching_items(tree, rules, fn _element, _matched_rules ->
               raise "should not be called"
             end) == tree
    end

    defp list_matched_elements(tree, css) do
      rules = CSSParser.parse(css)

      tree
      |> DOM.traverse_with_matching_items(rules, fn {tag, attrs, children}, _matched_rules ->
        {tag, [{"data-matched", ""} | attrs], children}
      end)
      |> DOM.all("[data-matched]")
      |> Enum.map(fn {tag, attrs, children} ->
        {tag, Map.new(attrs), children}
      end)
    end
  end

  describe "all/2" do
    setup do
      html =
        """
        <section id="main">
          <!--hidden-->
          <div class="container">
            <p class="intro featured" data-kind="primary" data-x="1">First</p>
            <p>Second</p>
            <a href="/">Link</a>
            <a href="/go" class="cta">Link</a>
          </div>
          <p>Outside div</p>
        </section>
        """

      {:ok, tree: Premailex.parse(html)}
    end

    test "with tag selector", %{tree: tree} do
      assert DOM.all(tree, "p") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]},
               {"p", [], ["Second"]},
               {"p", [], ["Outside div"]}
             ]
    end

    test "with universal tag selector", %{tree: tree} do
      assert [{"section", [{"id", "main"}], _}, {"div", _, _} | _] = DOM.all(tree, "*")
    end

    test "with id selector", %{tree: tree} do
      assert [{"section", [{"id", "main"}], _}] = DOM.all(tree, "#main")
    end

    test "with class selector", %{tree: tree} do
      assert DOM.all(tree, ".cta") == [
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]}
             ]
    end

    test "with class selector with multiple classes", %{tree: tree} do
      assert DOM.all(tree, ".intro") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]}
             ]

      assert DOM.all(tree, ".featured") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]}
             ]

      assert DOM.all(tree, ".intro.featured") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]}
             ]

      assert DOM.all(tree, ".intro.absent") == []
      assert DOM.all(tree, ".feature") == []
      assert DOM.all(tree, ".intr") == []
    end

    test "with class selector with substring in the middle of class" do
      tree = Premailex.parse(~s(<p class="my-intro-here">Mid</p>))

      assert DOM.all(tree, ".intro") == []
    end

    test "with attribute selector", %{tree: tree} do
      assert DOM.all(tree, "[href]") == [
               {"a", [{"href", "/"}], ["Link"]},
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]}
             ]

      assert DOM.all(tree, ~s(a[href="/go"])) == [
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]}
             ]
    end

    test "with pseudo-element selector", %{tree: tree} do
      assert DOM.all(tree, "p::before") == []
    end

    test "with pseudo-class selector with :first-child", %{tree: tree} do
      assert [
               {"section", _, _},
               {"div", _, _},
               {"p", [{"class", "intro featured"} | _], ["First"]}
             ] = DOM.all(tree, ":first-child")
    end

    test "with pseudo-class selector with :last-child", %{tree: tree} do
      assert [
               {"section", _, _},
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]},
               {"p", [], ["Outside div"]}
             ] = DOM.all(tree, ":last-child")
    end

    test "with pseudo-class selector with :only-child", %{tree: tree} do
      assert [{"section", _, _}] = DOM.all(tree, ":only-child")
    end

    test "with pseudo-class selector with :first-of-type", %{tree: tree} do
      assert DOM.all(tree, "p:first-of-type") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]},
               {"p", [], ["Outside div"]}
             ]
    end

    test "with pseudo-class selector with :last-of-type", %{tree: tree} do
      assert DOM.all(tree, "p:last-of-type") == [
               {"p", [], ["Second"]},
               {"p", [], ["Outside div"]}
             ]

      assert DOM.all(tree, "a:last-of-type") == [
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]}
             ]
    end

    test "with pseudo-class selector with :only-of-type", %{tree: tree} do
      assert [{"section", _, _}, {"div", _, _}, {"p", [], ["Outside div"]}] =
               DOM.all(tree, ":only-of-type")
    end

    test "with pseudo-class selector with :empty" do
      tree = Premailex.parse(~s(<div><p></p><p>x</p><br/></div>))

      assert DOM.all(tree, ":empty") == [{"p", [], []}, {"br", [], []}]
    end

    test "with pseudo-class selector with :root" do
      tree = Premailex.parse(~s(<p>a</p><div>b</div>))

      assert DOM.all(tree, ":root") == [{"p", [], ["a"]}, {"div", [], ["b"]}]
    end

    test "with pseudo-class selector with :nth-child", %{tree: tree} do
      assert DOM.all(tree, ":nth-child(2)") == [
               {"p", [], ["Second"]},
               {"p", [], ["Outside div"]}
             ]

      assert DOM.all(tree, ":nth-child(2n)") == [
               {"p", [], ["Second"]},
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]},
               {"p", [], ["Outside div"]}
             ]
    end

    test "with pseudo-class selector with :nth-of-type", %{tree: tree} do
      assert DOM.all(tree, "p:nth-of-type(2)") == [{"p", [], ["Second"]}]
      assert DOM.all(tree, "a:nth-of-type(1)") == [{"a", [{"href", "/"}], ["Link"]}]
    end

    test "with pseudo-class selector with :nth-last-child", %{tree: tree} do
      assert DOM.all(tree, ":nth-last-child(1)") == DOM.all(tree, ":last-child")
      assert DOM.all(tree, "div :nth-last-child(2)") == [{"a", [{"href", "/"}], ["Link"]}]
    end

    test "with pseudo-class selector with :nth-last-of-type", %{tree: tree} do
      assert DOM.all(tree, "p:nth-last-of-type(1)") == DOM.all(tree, "p:last-of-type")

      assert DOM.all(tree, "div p:nth-last-of-type(2)") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]}
             ]
    end

    test "with pseudo-class selector with invalid :nth-child expression", %{tree: tree} do
      assert capture_log(fn ->
               assert DOM.all(tree, ":nth-child(abc)") == []
             end) =~ "Invalid expression for :nth-child(abc). Ignoring."
    end

    test "with unsupported pseudo-class selector", %{tree: tree} do
      assert capture_log(fn ->
               assert DOM.all(tree, "a:hover") == []
             end) =~ "Pseudo-class :hover is not implemented. Ignoring."
    end

    test "with descendant combinator selector", %{tree: tree} do
      assert DOM.all(tree, "div p") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]},
               {"p", [], ["Second"]}
             ]
    end

    test "with child combinator selector", %{tree: tree} do
      assert DOM.all(tree, "section > p") == [{"p", [], ["Outside div"]}]
    end

    test "with child combinator selector with element without parent", %{tree: tree} do
      assert DOM.all(tree, "html > section") == []
    end

    test "with adjacent sibling combinator selector", %{tree: tree} do
      assert DOM.all(tree, "p.intro + p") == [{"p", [], ["Second"]}]
    end

    test "with general sibling combinator selector", %{tree: tree} do
      assert DOM.all(tree, "p ~ [href]") == [
               {"a", [{"href", "/"}], ["Link"]},
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]}
             ]
    end

    test "with column combinator selector", %{tree: tree} do
      assert capture_log(fn ->
               assert DOM.all(tree, "p || a") == []
             end) =~ "Column combinator (||) is not implemented. Ignoring."
    end

    test "with multiple selector groups", %{tree: tree} do
      assert DOM.all(tree, "p.intro, a.cta") == [
               {"p", [{"class", "intro featured"}, {"data-kind", "primary"}, {"data-x", "1"}],
                ["First"]},
               {"a", [{"href", "/go"}, {"class", "cta"}], ["Link"]}
             ]
    end

    test "with invalid selector", %{tree: tree} do
      assert capture_log(fn ->
               assert DOM.all(tree, "body#") == []
             end) =~ ~s(Invalid selector group "body#". Ignoring.)
    end
  end

  describe "reject/2" do
    setup do
      html =
        """
        <div>
          <!--c-->
          <p>a</p>
          <h1>b</h1>
          <section class="x">
            <p>c</p>
          </section>
          <article>
            <h1>d</h1>
            <p>e</p>
          </article>
        </div>\
        """

      {:ok, tree: Premailex.parse(html)}
    end

    test "rejects", %{tree: tree} do
      assert Xmerl.to_html(DOM.reject(tree, "h1, section.x")) ==
               """
               <div>
                 <!--c-->
                 <p>a</p>
                 <article>
                   <p>e</p>
                 </article>
               </div>\
               """
    end
  end

  test "text_content/1" do
    tree = Premailex.parse("<div>start <p>middle</p><!--c--> end</div>")

    assert DOM.text_content(tree) == "start middle end"
  end
end
