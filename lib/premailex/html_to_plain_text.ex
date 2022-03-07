defmodule Premailex.HTMLToPlainText do
  @moduledoc """
  Module that converts HTML emails to plain text.
  """
  alias Premailex.{HTMLParser, Util}

  @line_length 65

  @doc """
  Processes HTML string into a plain text string.

  ## Examples

      iex> Premailex.HTMLToPlainText.process("<html><body><ul><li>Test</li></ul></body></html>")
      "* Test"

  """
  @spec process(String.t() | Util.html_tree()) :: String.t()
  def process(html) when is_binary(html) do
    html
    |> HTMLParser.parse()
    |> process()
  end

  def process(tree) do
    tree
    |> clear_whitespace()
    |> line_breaks()
    |> horizontal_rules()
    |> images()
    |> links()
    |> headings()
    |> paragraphs()
    |> unordered_lists()
    |> ordered_lists()
    |> tables()
    |> HTMLParser.text()
    |> wordwrap()
    |> clear_linebreaks()
    |> String.trim()
  end

  defp images(html), do: Util.traverse(html, "img", &image(&1))

  defp image({_, attr, _}) do
    attr
    |> Enum.find({"", ""}, &(elem(&1, 0) == "alt"))
    |> elem(1)
  end

  defp line_breaks(html), do: Util.traverse(html, "br", &line_break(&1))
  defp line_break(_), do: "\n"

  defp headings(html), do: Util.traverse(html, Enum.map(1..6, &"h#{&1}"), &heading(&1))

  defp heading({type, _, content}) do
    text = HTMLParser.text(content)

    length =
      text
      |> String.split("\n")
      |> Enum.map(&String.length(&1))
      |> Enum.max()

    "\n\n" <> heading(type, text, length) <> "\n\n"
  end

  defp heading("h1", text, length) do
    heading_line = String.duplicate("*", length)
    heading_line <> "\n" <> text <> "\n" <> heading_line
  end

  defp heading("h2", text, length) do
    heading_line = String.duplicate("-", length)
    heading_line <> "\n" <> text <> "\n" <> heading_line
  end

  defp heading(_, text, length) do
    heading_line = String.duplicate("-", length)
    text <> "\n" <> heading_line
  end

  defp links(html), do: Util.traverse(html, "a", &link(&1))

  defp link({_, attr, content}) do
    url =
      attr
      |> Enum.find({"", ""}, &(elem(&1, 0) == "href"))
      |> elem(1)
      |> String.replace("mailto:", "")

    text = HTMLParser.text(content)

    link(String.trim(url), String.trim(text))
  end

  defp link(url, text), do: link(url, text, String.downcase(url) == String.downcase(text))
  defp link(_, "", _), do: ""
  defp link(url, _, true), do: url
  defp link(url, text, false), do: "#{text} (#{url})"

  defp paragraphs(html), do: Util.traverse(html, "p", &paragraph(&1))
  defp paragraph({_, _, content}), do: HTMLParser.text(content) <> "\n\n"

  defp horizontal_rules(html), do: Util.traverse(html, "hr", &horizontal_rule(&1))

  defp horizontal_rule({_, _, _}), do: String.duplicate("-", @line_length) <> "\n\n"

  defp unordered_lists(html), do: Util.traverse(html, "ul", &unordered_list_items(&1))

  defp unordered_list_items({_, _, items}) do
    items
    |> Util.traverse("li", &unordered_list_item(&1))
    |> Enum.join("")
  end

  defp unordered_list_item({_, _, content}) do
    "* " <> HTMLParser.text(content) <> "\n"
  end

  defp ordered_lists(html), do: Util.traverse(html, "ol", &ordered_list_items(&1))

  defp ordered_list_items({_, _, items}) do
    items
    |> Util.traverse_reduce("li", &ordered_list_item(&1, &2))
    |> elem(0)
    |> Enum.join("")
  end

  defp ordered_list_item({_, _, content}, acc) do
    "#{acc + 1}. " <> HTMLParser.text(content) <> "\n"
  end

  defp tables(html), do: Util.traverse(html, "table", &table(&1))

  defp table({_, _, table_rows}) do
    # Calling tables/1 to make sure all nested tables have been processed
    table_rows
    |> tables()
    |> flatten_table_body()
    |> Util.traverse("tr", &table_rows(&1))
    |> Enum.join("")
  end

  defp table_rows({_, _, [{"th", _, _} | _rest] = table_cells}) do
    table_cells
    |> Util.traverse("th", &HTMLParser.text(&1))
    |> Enum.join(" ")
    |> Kernel.<>("\n")
  end

  defp table_rows({_, _, table_cells}) do
    table_cells
    |> Util.traverse("td", &HTMLParser.text(&1))
    |> Enum.join(" ")
    |> Kernel.<>("\n")
  end

  defp flatten_table_body(elements), do: Enum.flat_map(elements, &remove_tbody/1)

  defp remove_tbody({"tbody", [], table_cells}), do: table_cells
  defp remove_tbody(elem), do: [elem]

  defp wordwrap(text) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", &wrap_paragraph(String.trim(&1)))
  end

  defp wrap_paragraph(""), do: ""

  defp wrap_paragraph(string) do
    [word | rest] = String.split(string, ~r/\s+/, trim: true)

    rest |> lines_assemble(@line_length, String.length(word), word, []) |> Enum.join("\n")
  end

  defp lines_assemble([], _, _, line, acc), do: [line | acc] |> Enum.reverse()

  defp lines_assemble([word | rest], max, line_length, line, acc) do
    if line_length + 1 + String.length(word) > max do
      lines_assemble(rest, max, String.length(word), word, [line | acc])
    else
      lines_assemble(rest, max, line_length + 1 + String.length(word), line <> " " <> word, acc)
    end
  end

  defp clear_linebreaks(text), do: Regex.replace(~r/[\n]{3,}/, text, "\n\n")

  defp clear_whitespace(list) when is_list(list) do
    list = Enum.map(list, &clear_whitespace(&1))

    list
    |> Enum.all?(&is_inline_element?/1)
    |> case do
      true -> list
      false -> Enum.reject(list, &is_empty?/1)
    end
  end

  defp clear_whitespace({elem, attr, children}) do
    {elem, attr, clear_whitespace(children)}
  end

  defp clear_whitespace(any), do: any

  defp is_empty?(text) when is_binary(text) do
    String.trim(text) == ""
  end

  defp is_empty?(_any), do: false

  @inline_elements [
    "a",
    "abbr",
    "acronym",
    "b",
    "bdo",
    "big",
    "br",
    "button",
    "cite",
    "code",
    "dfn",
    "em",
    "i",
    "img",
    "input",
    "kbd",
    "label",
    "map",
    "object",
    "q",
    "samp",
    "script",
    "select",
    "small",
    "span",
    "strong",
    "sub",
    "sup",
    "textarea",
    "time",
    "tt",
    "var"
  ]

  defp is_inline_element?({element, _attrs, _children})
       when element in @inline_elements,
       do: true

  defp is_inline_element?({_element, _attrs, _children}), do: false
  defp is_inline_element?(_any), do: true
end
