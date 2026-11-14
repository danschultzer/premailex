if Code.ensure_loaded?(Floki) do
  defmodule Premailex.HTMLParser.Floki do
    @moduledoc """
    HTML parser implementation using Floki.

    Add `Floki` to your dependencies in `mix.exs` to use this parser:

        defp deps do
          [
            {:floki, "~> 0.24"}
          ]
        end
    """

    @behaviour Premailex.HTMLParser

    @impl true
    @doc false
    def parse(html) do
      html
      |> retain_inline_whitespace()
      |> Floki.parse_document()
      |> case do
        {:ok, document} ->
          document

        {:error, reason} when is_binary(reason) ->
          raise ArgumentError, "could not parse HTML with Floki: #{reason}"
      end
    end

    # Floki strips whitespace text nodes between tags, which can cause errors
    # such as: https://github.com/mochi/mochiweb/issues/166
    #
    # To both prevent this and preserve whitespace like other HTML parsers,
    # each whitespace character is encoded as a numeric HTML entity so Floki's
    # parser treats it as content.
    defp retain_inline_whitespace(html) do
      Regex.replace(~r/>(\s+)</, html, fn _full, whitespace ->
        encoded = for <<char <- whitespace>>, into: "", do: "&##{char};"

        ">#{encoded}<"
      end)
    end

    @impl true
    @doc false
    def to_html(tree), do: Floki.raw_html(tree)
  end
end
