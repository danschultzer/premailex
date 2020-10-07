defmodule Premailex.HTMLInlineStyles do
  @moduledoc """
  Module that processes inline styling in HMTL.
  """

  alias Premailex.{CSSParser, HTMLParser, Util}

  @doc """
  Processes an HTML string adding inline styles.

  Options:
    * `css_selector` - the style tags to be processed for inline styling, defaults to `style,link[rel="stylesheet"][href]`
    * `optimize` - list or atom option for optimizing the output. The following values can be used:
      * `:none` - no optimization (default)
      * `:all` - apply all optimization steps
      * `:remove_style_tags` - Remove style tags (can be combined in a list)
  """
  @spec process(String.t(), Keyword.t()) :: String.t()
  def process(html, options \\ []) do
    css_selector = Keyword.get(options, :css_selector, "style,link[rel=\"stylesheet\"][href]")
    optimize_steps = Keyword.get(options, :optimize, :none)
    tree = HTMLParser.parse(html)

    tree
    |> load_styles(css_selector)
    |> apply_styles(tree)
    |> normalize_styles()
    |> optimize(optimize_steps, css_selector: css_selector)
    |> HTMLParser.to_string()
  end

  defp load_styles(tree, css_selector) do
    tree
    |> HTMLParser.all(css_selector)
    |> Enum.map(&load_css(&1))
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.reduce([], &Enum.concat(&1, &2))
  end

  defp apply_styles(styles, tree) do
    Enum.reduce(styles, tree, &add_rule_set_to_html(&1, &2))
  end

  defp load_css({"style", _, content}) do
    content
    |> Enum.join("\n")
    |> CSSParser.parse()
  end

  defp load_css({"link", attrs, _}), do: load_css({"link", List.keyfind(attrs, "href", 0)})

  defp load_css({"link", {"href", url}}) do
    {http_adapter, opts} = http_adapter()

    :get
    |> http_adapter.request(url, nil, [], opts)
    |> parse_body()
  end

  defp parse_body({:ok, %{status: status, body: body}}) when status in 200..399 do
    CSSParser.parse(body)
  end
  defp parse_body(_any), do: nil

  defp add_rule_set_to_html(%{selector: selector, rules: rules, specificity: specificity}, html) do
    html
    |> HTMLParser.all(selector)
    |> Enum.reduce(html, &update_style_for_html(&2, &1, rules, specificity))
  end

  defp update_style_for_html(html, needle, rules, specificity) do
    Util.traverse_until_first(html, needle, &update_style_for_element(&1, rules, specificity))
  end

  defp update_style_for_element({name, attrs, children}, rules, specificity) do
    style =
      attrs
      |> Enum.into(%{})
      |> Map.get("style", nil)
      |> set_inline_style_specificity()
      |> add_styles_with_specificity(rules, specificity)

    attrs =
      attrs
      |> Enum.filter(fn {name, _} -> name != "style" end)
      |> Enum.concat([{"style", style}])

    {name, attrs, children}
  end

  defp set_inline_style_specificity(nil), do: ""
  defp set_inline_style_specificity("[SPEC=" <> _rest = style), do: style
  defp set_inline_style_specificity(style), do: "[SPEC=1000[#{style}]]"

  defp add_styles_with_specificity(style, rules, specificity) do
    "#{style}[SPEC=#{specificity}[#{CSSParser.to_string(rules)}]]"
  end

  defp normalize_styles(html) do
    html
    |> HTMLParser.all("[style]")
    |> Enum.reduce(html, &merge_styles(&2, &1))
  end

  defp merge_styles(html, needle) do
    Util.traverse_until_first(html, needle, &merge_style/1)
  end

  defp merge_style({name, attrs, children}) do
    current_style =
      attrs
      |> Enum.into(%{})
      |> Map.get("style")

    style =
      ~r/\[SPEC\=([\d]+)\[(.[^\]\]]*)\]\]/
      |> Regex.scan(current_style)
      |> Enum.map(fn [_, specificity, rule] ->
        %{specificity: specificity, rules: CSSParser.parse_rules(rule)}
      end)
      |> CSSParser.merge()
      |> CSSParser.to_string()
      |> case do
        ""    -> current_style
        style -> style
      end

    attrs =
      attrs
      |> Enum.filter(fn {name, _} -> name != "style" end)
      |> Enum.concat([{"style", style}])

    {name, attrs, children}
  end

  defp optimize(tree, steps, options) when is_atom(steps), do: optimize(tree, [steps], options)
  defp optimize(tree, [:none], _options), do: tree
  defp optimize(tree, [:all], options), do: optimize(tree, [:remove_style_tags], options)

  defp optimize(tree, steps, options) do
    maybe_remove_style_tags(tree, steps, options)
  end

  defp maybe_remove_style_tags(tree, steps, options) do
    case Enum.member?(steps, :remove_style_tags) do
      true -> HTMLParser.filter(tree, Keyword.get(options, :css_selector))
      false -> tree
    end
  end

  defp http_adapter do
    case Application.get_env(:premailex, :http_adapter, Premailex.HTTPAdapter.Httpc) do
      {adapter, opts} -> {adapter, opts}
      adapter         -> {adapter, nil}
    end
  end
end
