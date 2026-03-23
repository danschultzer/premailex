defmodule Premailex.HTMLParser.ParserCompatibilityTest do
  use ExUnit.Case

  alias Premailex.HTMLParser

  @parsers [
    Premailex.HTMLParser.Floki,
    Premailex.HTMLParser.Meeseeks,
    Premailex.HTMLParser.LazyHTML
  ]

  @test_html """
  <html>
    <head>
      <title>Test Page</title>
    </head>
    <body>
      <div class="container" id="main">
        <h1>Hello World</h1>
        <p class="intro">This is a test paragraph.</p>
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
        </ul>
        <a href="https://example.com" class="link">Link</a>
      </div>
    </body>
  </html>
  """

  @test_html_fragment """
  <div class="container">
    <p>Paragraph 1</p>
    <p class="highlight">Paragraph 2</p>
    <span>Text</span>
  </div>
  """

  setup do
    original_parser = Application.get_env(:premailex, :html_parser, Premailex.HTMLParser.Floki)

    on_exit(fn ->
      Application.put_env(:premailex, :html_parser, original_parser)
    end)

    {:ok, original_parser: original_parser}
  end

  describe "parse/1" do
    test "all parsers produce equivalent parse results" do
      results =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      html_strings =
        Enum.map(results, fn tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))

          HTMLParser.to_string(tree)
          |> normalize_html()
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end

    test "all parsers handle fragments consistently" do
      results =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html_fragment)
        end)

      html_strings =
        Enum.map(results, fn tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))
          html = HTMLParser.to_string(tree)

          html =
            Regex.replace(~r/<html[^>]*>.*?<body[^>]*>(.*?)<\/body>.*?<\/html>/is, html, "\\1")

          normalize_html(html)
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end
  end

  describe "all/2" do
    test "all parsers find the same elements with tag selector" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.all(tree, "p")
        end)

      html_strings =
        Enum.map(results, fn result_tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))

          HTMLParser.to_string(result_tree)
          |> normalize_html()
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end

    test "all parsers find the same elements with class selector" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.all(tree, ".container")
        end)

      html_strings =
        Enum.map(results, fn result_tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))

          HTMLParser.to_string(result_tree)
          |> normalize_html()
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end

    test "all parsers find the same elements with id selector" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.all(tree, "#main")
        end)

      # Compare by converting to HTML strings (ignores structural differences)
      html_strings =
        Enum.map(results, fn result_tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))

          HTMLParser.to_string(result_tree)
          |> normalize_html()
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end

    test "all parsers find the same elements with descendant selector" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.all(tree, "div li")
        end)

      html_strings =
        Enum.map(results, fn result_tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))

          HTMLParser.to_string(result_tree)
          |> normalize_html()
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end
  end

  describe "filter/2" do
    test "all parsers filter out the same elements" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.filter(tree, "p")
        end)

      html_strings =
        Enum.map(results, fn result_tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))

          HTMLParser.to_string(result_tree)
          |> normalize_html()
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end

    test "all parsers filter out elements with class selector" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.filter(tree, ".intro")
        end)

      html_strings =
        Enum.map(results, fn result_tree ->
          Application.put_env(:premailex, :html_parser, List.first(@parsers))

          HTMLParser.to_string(result_tree)
          |> normalize_html()
        end)

      assert Enum.all?(html_strings, &(&1 == List.first(html_strings)))
    end
  end

  describe "to_string/1" do
    test "all parsers serialize to equivalent HTML" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.to_string(tree)
        end)

      normalized_results = Enum.map(results, &normalize_html/1)
      assert Enum.all?(normalized_results, &(&1 == List.first(normalized_results)))
    end
  end

  describe "text/1" do
    test "all parsers extract the same text content" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.text(tree)
        end)

      normalized_results =
        Enum.map(results, fn text ->
          text |> String.replace(~r/\s+/, "")
        end)

      assert Enum.all?(normalized_results, &(&1 == List.first(normalized_results)))
    end

    test "all parsers extract text from fragments consistently" do
      trees =
        Enum.map(@parsers, fn parser ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.parse(@test_html_fragment)
        end)

      results =
        Enum.map(Enum.zip([@parsers, trees]), fn {parser, tree} ->
          Application.put_env(:premailex, :html_parser, parser)
          HTMLParser.text(tree)
        end)

      normalized_results =
        Enum.map(results, fn text ->
          text |> String.replace(~r/\s+/, "")
        end)

      assert Enum.all?(normalized_results, &(&1 == List.first(normalized_results)))
    end
  end

  # Helper functions

  # Normalize HTML string for comparison
  defp normalize_html(html) do
    html
    |> String.replace(~r/>\s+</, "><")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
