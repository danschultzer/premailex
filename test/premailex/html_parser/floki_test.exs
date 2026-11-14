defmodule Premailex.HTMLParser.FlokiTest do
  use ExUnit.Case
  doctest Premailex.HTMLParser.Floki

  alias __MODULE__.FakeHTMLParser
  alias Premailex.HTMLParser.Floki

  describe "parse/1" do
    test "with document" do
      assert Floki.parse("""
             <html>
               <body>
                 <p>Hi</p>
               </body>
             </html>
             """) ==
               [
                 {"html", [],
                  [
                    "\n  ",
                    {"body", [], ["\n    ", {"p", [], ["Hi"]}, "\n  "]},
                    "\n"
                  ]}
               ]
    end

    test "with document fragment" do
      assert Floki.parse("<p>Hi</p>") == [{"p", [], ["Hi"]}]

      assert Floki.parse("<h1>Hi</h1> <p>there</p>") ==
               [{"h1", [], ["Hi"]}, " ", {"p", [], ["there"]}]
    end

    test "with invalid HTML" do
      Application.put_env(:floki, :html_parser, FakeHTMLParser)
      on_exit(fn -> Application.delete_env(:floki, :html_parser) end)

      assert_raise ArgumentError,
                   ~r/could not parse HTML with Floki: invalid/,
                   fn -> Floki.parse("invalid") end
    end
  end

  test "to_html/1" do
    assert Floki.to_html([{"html", [], [{"body", [], [{"p", [], ["Hi"]}]}]}]) ==
             "<html><body><p>Hi</p></body></html>"
  end

  defmodule FakeHTMLParser do
    @behaviour Elixir.Floki.HTMLParser

    def parse_document("invalid", _opts), do: {:error, "invalid"}

    def parse_document_with_attributes_as_maps(_html, _opts), do: {:ok, []}

    def parse_fragment(_html, _opts), do: {:error, []}

    def parse_fragment_with_attributes_as_maps(_html, _opts), do: {:error, []}
  end
end
