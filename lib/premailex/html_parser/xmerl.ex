defmodule Premailex.HTMLParser.Xmerl do
  @moduledoc """
  A simple HTML parser using Erlang's built-in `m::xmerl` library.

  This is used as a fallback when no other HTML parsing libraries are
  available. It is designed for well-formed XML-like HTML, but it does not
  support real-world HTML, which is often not valid XML.

  For more robust HTML parsing, use `Premailex.HTMLParser.LazyHTML`,
  `Premailex.HTMLParser.Floki`, or `Premailex.HTMLParser.Meeseeks`.

  `m::xmerl_sax_parser` is used to prevent atom leaks.

  ## Parser limitations

    * Only well-formed XML-like HTML is supported. HTML5 syntax such as
      unquoted attribute values (`<div data-x=a>`) or unclosed non-void tags is
      rejected.

    * A round-trip through this parser is not lossless:

      * XML normalises whitespace in attribute values (newlines and tabs become
        spaces).

      * Named entities are decoded to characters and serialized as the literal
        character (e.g. `&copy;` round-trips as `©`).

      * `xmlns:*` namespace declarations always appear first in the attribute
        list, regardless of source position (`m::xmerl_sax_parser` removes them
        from the element's attribute list).

      * Void elements always serialize as `<br>` (HTML style), regardless of
        whether the source used `<br/>`.
  """
  @behaviour Premailex.HTMLParser

  @fragment_root "premailex-root"
  @comment_tag "premailex-comment"
  @void_tags ~w(area base br col embed hr img input link meta param source track wbr)

  # This regex ensures all void tags are captured when unclosed, as xmerl fails
  # if void tags are not properly closed.
  @void_tags_regex Regex.compile!(
                     ~s{<(#{Enum.join(@void_tags, "|")})(\\b(?:\\s(?:[^"'>]|"[^"]*"|'[^']*')*)?)>},
                     "i"
                   )

  @html_entities :code.priv_dir(:premailex)
                 |> Path.join("entities.txt")
                 |> File.read!()
                 |> String.split("\n", trim: true)
                 |> Map.new(fn line ->
                   [entity | codepoints] = String.split(line, " ")
                   chars = codepoints |> Enum.map(&String.to_integer/1) |> IO.chardata_to_string()

                   {entity, chars}
                 end)

  @impl true
  @doc false
  def parse(html) do
    html
    |> normalize_html()
    |> wrap_fragment()
    |> parse_with_xmerl()
    |> unwrap_fragment()
  end

  defp normalize_html(html) do
    html
    |> String.replace(~r/<!DOCTYPE[^>]*>/i, "")
    |> replace_comments_with_placeholders()
    |> close_void_elements()
  end

  defp replace_comments_with_placeholders(html) do
    Regex.replace(~r/<!--(.*?)-->/s, html, fn _full, comment ->
      encoded_comment = Base.url_encode64(comment, padding: false)

      ~s(<#{@comment_tag} data-comment="#{encoded_comment}"/>)
    end)
  end

  defp close_void_elements(html) do
    Regex.replace(@void_tags_regex, html, fn _full, tag, attrs ->
      attrs
      |> String.trim()
      |> String.ends_with?("/")
      |> case do
        true -> "<#{tag}#{attrs}>"
        false -> "<#{tag}#{attrs}/>"
      end
    end)
  end

  defp wrap_fragment(html), do: "<#{@fragment_root}>#{html}</#{@fragment_root}>"

  defp parse_with_xmerl(html) do
    opts = [
      event_fun: &sax_event/3,
      event_state: %{stack: [], result: nil, namespace_attrs: []},
      # HTML entities are handled with `replace_html_entities/1`.
      external_entities: :none,
      fail_undeclared_ref: false
    ]

    case :xmerl_sax_parser.stream(String.to_charlist(html), opts) do
      {:ok, %{result: result}, _rest} ->
        result

      {:fatal_error, _location, reason, _end_tags, _state} when is_list(reason) ->
        raise ArgumentError,
              """
              could not parse HTML with #{inspect(__MODULE__)}: #{to_string(reason)}

              The built-in fallback parser only supports well-formed, XML-like HTML.
              For more permissive HTML parsing, add LazyHTML, Floki, or Meeseeks to your dependencies.
              """
    end
  end

  defp sax_event({:startPrefixMapping, prefix, uri}, _location, state) do
    namespace =
      case prefix do
        [] -> {"xmlns", List.to_string(uri)}
        _prefix -> {"xmlns:" <> List.to_string(prefix), List.to_string(uri)}
      end

    %{state | namespace_attrs: [namespace | state.namespace_attrs]}
  end

  defp sax_event({:startElement, _uri, _local_name, qname, attrs}, _location, state) do
    tag =
      case qname do
        {[], name} -> List.to_string(name)
        {prefix, name} -> List.to_string(prefix) <> ":" <> List.to_string(name)
      end

    parsed_attrs =
      Enum.reverse(state.namespace_attrs) ++
        Enum.map(attrs, &sax_attribute_to_pair/1)

    %{state | stack: [{tag, parsed_attrs, []} | state.stack], namespace_attrs: []}
  end

  defp sax_event({type, chars}, _location, state)
       when type in ~w(characters ignorableWhitespace)a do
    [{tag, attrs, children} | rest] = state.stack
    text = replace_html_entities(List.to_string(chars))

    %{state | stack: [{tag, attrs, [text | children]} | rest]}
  end

  defp sax_event({:endElement, _uri, _local_name, _qname}, _location, state) do
    [{tag, attrs, children} | rest] = state.stack

    node =
      case {tag, attrs} do
        {@comment_tag, attrs} -> {:comment, decode_comment(attrs)}
        _ -> {tag, attrs, Enum.reverse(children)}
      end

    case rest do
      [] ->
        %{state | stack: [], result: node}

      [{parent_tag, parent_attrs, parent_children} | remaining] ->
        %{state | stack: [{parent_tag, parent_attrs, [node | parent_children]} | remaining]}
    end
  end

  defp sax_event(_event, _location, state), do: state

  defp sax_attribute_to_pair({_uri, prefix, name, value}) do
    attr_name =
      case prefix do
        [] -> List.to_string(name)
        _prefix -> List.to_string(prefix) <> ":" <> List.to_string(name)
      end

    {attr_name, List.to_string(value)}
  end

  defp replace_html_entities(text) do
    Regex.replace(~r/&([a-zA-Z0-9]+);/, text, fn full, entity ->
      Map.get(@html_entities, "&#{entity};", full)
    end)
  end

  defp decode_comment(attrs) do
    {_, encoded} = List.keyfind!(attrs, "data-comment", 0)

    Base.url_decode64!(encoded, padding: false)
  end

  defp unwrap_fragment({@fragment_root, _attrs, children}), do: children

  @impl true
  @doc false
  def to_html(tree) do
    Enum.map_join(tree, &serialize_node/1)
  end

  defp serialize_node({:comment, text}), do: "<!--#{text}-->"

  defp serialize_node(text) when is_binary(text), do: serialize_text_content(text)

  defp serialize_node({tag, attrs, _children}) when tag in @void_tags do
    "<#{tag}#{serialize_attrs(attrs)}>"
  end

  defp serialize_node({tag, attrs, children}) do
    "<#{tag}#{serialize_attrs(attrs)}>#{Enum.map_join(children, &serialize_node/1)}</#{tag}>"
  end

  defp serialize_text_content(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp serialize_attrs(attrs) do
    Enum.map_join(attrs, fn {name, value} -> ~s( #{name}="#{escape_attr(value)}") end)
  end

  defp escape_attr(value) do
    value
    |> serialize_text_content()
    |> String.replace("\"", "&quot;")
  end
end
