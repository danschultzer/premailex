defmodule Premailex do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)
             # Replace Markdown-linked HexDocs cross-references with plain
             # references so ExDoc can resolve links correctly.
             |> then(&Regex.replace(~r/\[(`[^`]+`)\]\([^)]+\)/, &1, "\\1"))
             # Convert Markdown OTP module references to ExDoc format.
             |> then(&Regex.replace(~r/`(:[a-z]+)`/, &1, "`m:\\1`"))
             |> String.trim()

  require Logger

  @type html :: String.t()
  @type html_element :: {String.t(), [{String.t(), String.t()}], [html_node()]}
  @type html_node :: html_element() | {:comment, String.t()} | String.t()
  @type html_tree :: [html_node()]

  @doc """
  Parses an HTML string into a `t:html_tree/0`.

  ## Options

    * `:html_parser` - HTML parser to use (see `Premailex.HTMLParser`);

  ## Examples

      iex> Premailex.parse(~s(<p class="lead">Hello</p>))
      [{"p", [{"class", "lead"}], ["Hello"]}]
  """
  @spec parse(html(), Keyword.t()) :: html_tree()
  def parse(html, options \\ []) do
    html_parser = Keyword.get_lazy(options, :html_parser, &html_parser/0)

    html_parser.parse(html)
  end

  defp html_parser do
    case Application.get_env(:premailex, :html_parser) || default_html_parser() do
      mod when is_atom(mod) -> mod
      other -> raise "expected :html_parser to be an atom, got: #{inspect(other)}"
    end
  end

  defp default_html_parser do
    cond do
      Code.ensure_loaded?(LazyHTML) ->
        Premailex.HTMLParser.LazyHTML

      Code.ensure_loaded?(Floki) ->
        Premailex.HTMLParser.Floki

      Code.ensure_loaded?(Meeseeks) ->
        Premailex.HTMLParser.Meeseeks

      true ->
        Premailex.HTMLParser.Xmerl
    end
  end

  @doc """
  Converts a `t:html_tree/0` into an HTML string.

  ## Options

    * `:html_parser` - HTML parser to use (see `Premailex.HTMLParser`);

  ## Examples

      iex> Premailex.to_html([{"p", [{"class", "lead"}], ["Hello"]}])
      ~s(<p class="lead">Hello</p>)
  """
  @spec to_html(html_tree(), Keyword.t()) :: html()
  def to_html(tree, options \\ []) do
    html_parser = Keyword.get_lazy(options, :html_parser, &html_parser/0)

    html_parser.to_html(tree)
  end

  @doc """
  Adds inline styles to an HTML string or `t:html_tree/0`.

  ## Options

    * `:html_parser` - HTML parser to use (see `Premailex.HTMLParser`);

    * `:http_adapter` - HTTP adapter to use for fetching external stylesheets
      (see `Premailex.HTTPAdapter`);

    * `:remove_style_tags` - whether to remove the `<style>` and `<link>` tags
      after inlining. Defaults to false;

  ## Examples

      iex> Premailex.to_inline_css(
      ...> ~s(<html><head>
      ...>   <style>p{background-color: #fff;}</style>
      ...> </head><body>
      ...>   <p style="color: #000;">Text</p>
      ...> </body></html>))
      ~s(<html><head>
         <style>p{background-color: #fff;}</style>
       </head><body>
         <p style="background-color: #fff; color: #000;">Text</p>
       </body></html>)
  """
  @spec to_inline_css(html() | html_tree(), Keyword.t()) :: html()
  def to_inline_css(html_or_tree, options \\ []) do
    options =
      options
      |> Keyword.put_new_lazy(:html_parser, &html_parser/0)
      |> Keyword.put_new_lazy(:http_adapter, &http_adapter/0)

    do_to_inline_css(html_or_tree, options)
  end

  defp http_adapter,
    do: Application.get_env(:premailex, :http_adapter, Premailex.HTTPAdapter.Httpc)

  defp do_to_inline_css(html, options) when is_binary(html) do
    html
    |> parse(options)
    |> do_to_inline_css(options)
  end

  defp do_to_inline_css(tree, options) do
    css_selector = Keyword.get(options, :css_selector, "style,link[rel=\"stylesheet\"][href]")
    css_rules = map_css_rules(tree, css_selector, options)

    options
    |> Keyword.get(:remove_style_tags, false)
    |> case do
      true -> Premailex.DOM.reject(tree, css_selector)
      false -> tree
    end
    |> Premailex.HTMLInlineStyles.process(css_rules)
    |> to_html(options)
  end

  defp map_css_rules(tree, css_selector, options) do
    tree
    |> Premailex.DOM.all(css_selector)
    |> Enum.flat_map(fn node ->
      node
      |> load_css(options)
      |> Premailex.CSSParser.parse()
    end)
  end

  defp load_css({"style", _, content}, _options) do
    Enum.join(content, "\n")
  end

  defp load_css({"link", attrs, _}, options) do
    case List.keyfind(attrs, "href", 0) do
      {"href", url} -> load_url(url, options)
      nil -> ""
    end
  end

  defp load_url(url, options) do
    {http_adapter, opts} =
      case Keyword.fetch!(options, :http_adapter) do
        {adapter, opts} -> {adapter, opts}
        adapter -> {adapter, nil}
      end

    case http_adapter.request(:get, url, nil, [], opts) do
      {:ok, %{status: status, body: body}} when status in 200..399 ->
        body

      {:ok, %{status: status}} ->
        Logger.warning("Ignoring #{url} styles due to unexpected HTTP response status: #{status}")

        ""

      {:error, error} ->
        Logger.warning(
          "Ignoring #{url} styles due to error in #{inspect(http_adapter)}:\n\n#{inspect(error)}"
        )

        ""
    end
  end

  @doc """
  Converts an HTML string or `t:html_tree/0` to plain text.

  ## Options

    * `:html_parser` - HTML parser to use (see `Premailex.HTMLParser`);

  ## Examples

      iex> Premailex.to_text(
      ...> ~s(<html><head>
      ...>   <style>p{background-color:#fff;}</style>
      ...> </head><body>
      ...>   <p style="color:#000;">Text</p>
      ...> </body></html>))
      "Text"
  """
  @spec to_text(html() | html_tree(), Keyword.t()) :: String.t()
  def to_text(html_or_tree, options \\ []) do
    options = Keyword.put_new_lazy(options, :html_parser, &html_parser/0)

    do_to_text(html_or_tree, options)
  end

  defp do_to_text(html, options) when is_binary(html) do
    html
    |> parse(options)
    |> do_to_text(options)
  end

  defp do_to_text(tree, _options) do
    Premailex.HTMLToPlainText.process(tree)
  end
end
