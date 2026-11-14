defmodule Premailex.HTMLParser.XmerlTest do
  use ExUnit.Case

  alias Premailex.HTMLParser.Xmerl

  describe "parse/1" do
    test "with empty" do
      assert Xmerl.parse("") == []
    end

    test "with doctype declaration" do
      tree = Xmerl.parse("<!DOCTYPE html><div>content</div>")

      assert tree == [{"div", [], ["content"]}]
    end

    test "with undeclared XML references" do
      tree = Xmerl.parse("<p>&nbsp;</p>")

      assert [{"p", [], ["\u00A0"]}] = tree
    end

    test "with comments" do
      tree = Xmerl.parse("<div><!--comment--></div>")

      assert [{"div", [], [{:comment, "comment"}]}] = tree
    end

    test "with void elements" do
      tree =
        Xmerl.parse(~s(<div><img src="/pixel" alt="pixel"/><img src='test'><br/><br></div>))

      assert [
               {"div", [],
                [
                  {"img", [{"src", "/pixel"}, {"alt", "pixel"}], []},
                  {"img", [{"src", "test"}], []},
                  {"br", [], []},
                  {"br", [], []}
                ]}
             ] = tree
    end

    test "with malformed XML" do
      assert_raise ArgumentError,
                   ~r/could not parse HTML with Premailex.HTMLParser.Xmerl: EndTag: :div, does not match StartTag/,
                   fn -> Xmerl.parse("<html><body><div><p>broken</div></body></html>") end

      assert_raise ArgumentError,
                   ~r/could not parse HTML with Premailex.HTMLParser.Xmerl: ', \" or whitespace expected/,
                   fn -> Xmerl.parse("<p data-x=a>Paragraph</p>") end
    end

    test "with namespaced elements and attributes" do
      tree =
        Xmerl.parse(
          ~s(<a xmlns="urn:test" xmlns:x="urn:x" x:href="/go"><x:child class="test">Body</x:child></a>)
        )

      assert [{"a", [attr_1, attr_2, attr_3], [{"x:child", [{"class", "test"}], ["Body"]}]}] =
               tree

      assert attr_1 == {"xmlns", "urn:test"}
      assert attr_2 == {"xmlns:x", "urn:x"}
      assert attr_3 == {"x:href", "/go"}
    end

    test "with ignorable whitespace" do
      assert Xmerl.parse("""
                 <div>   <p> </p>\t
               </div>\t
             """) == ["    ", {"div", [], ["   ", {"p", [], [" "]}, "\t\n  "]}, "\t\n"]
    end

    test "with whitespace in attribute value" do
      assert Xmerl.parse(~s(<div data-x="a\nb"></div>)) == [{"div", [{"data-x", "a b"}], []}]
      assert Xmerl.parse(~s(<div data-x="a\tb"></div>)) == [{"div", [{"data-x", "a b"}], []}]
    end

    test "with html entities" do
      assert Xmerl.parse("&copy; &nbsp; &lt;") == ["\u00A9 \u00A0 <"]
      assert Xmerl.parse("&unknown;") == ["&unknown;"]
    end

    test "with single element" do
      tree = Xmerl.parse("<span>solo</span>")

      assert tree == [{"span", [], ["solo"]}]
    end

    test "with multiple root elements" do
      tree = Xmerl.parse("<span>one</span><span>two</span>")

      assert tree == [{"span", [], ["one"]}, {"span", [], ["two"]}]
    end
  end

  describe "to_html/1" do
    test "with comment" do
      assert Xmerl.to_html([{:comment, "note"}]) == "<!--note-->"
    end

    test "with text" do
      assert Xmerl.to_html(["a & b < c > d ©"]) == "a &amp; b &lt; c &gt; d ©"
    end

    test "with void element" do
      assert Xmerl.to_html([{"br", [], []}]) == "<br>"
      assert Xmerl.to_html([{"img", [{"src", "/p"}], []}]) == ~s(<img src="/p">)
    end

    test "with element" do
      assert Xmerl.to_html([{"div", [], []}]) == "<div></div>"

      assert Xmerl.to_html([{"div", [], [{"p", [], ["x"]}, {"p", [], ["y"]}]}]) ==
               "<div><p>x</p><p>y</p></div>"

      assert Xmerl.to_html([{"p", [], ["text ", {:comment, "c"}, " more"]}]) ==
               "<p>text <!--c--> more</p>"
    end

    test "with attributes" do
      assert Xmerl.to_html([{"a", [{"href", "/"}, {"class", "x"}], []}]) ==
               ~s(<a href="/" class="x"></a>)

      assert Xmerl.to_html([{"a", [{"xlink:href", "/ns"}], []}]) ==
               ~s(<a xlink:href="/ns"></a>)

      assert Xmerl.to_html([{"a", [{"data-x", ~s(a & "b" <c>)}], []}]) ==
               ~s(<a data-x="a &amp; &quot;b&quot; &lt;c&gt;"></a>)
    end

    test "with list input" do
      assert Xmerl.to_html([{"p", [], ["a"]}, "b"]) == "<p>a</p>b"
    end

    test "with parse round-trip" do
      tree = Xmerl.parse(~s(<div id="x"><p data-x="a &amp; b">Test</p></div>))

      assert Xmerl.to_html(tree) ==
               ~s(<div id="x"><p data-x="a &amp; b">Test</p></div>)
    end
  end
end
