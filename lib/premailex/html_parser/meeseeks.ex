if Code.ensure_loaded?(Meeseeks) do
  defmodule Premailex.HTMLParser.Meeseeks do
    @moduledoc """
    HTML parser implementation using Meeseeks.

    Add `Meeseeks` to your dependencies in `mix.exs` to use this parser:

        defp deps do
          [
            {:meeseeks, "~> 0.11"}
          ]
        end
    """
    @behaviour Premailex.HTMLParser

    @impl true
    @doc false
    def parse(html) do
      case Meeseeks.parse(html) do
        %Meeseeks.Document{} = document ->
          document
          |> Meeseeks.tree()
          |> unwrap_fragment(html)

        {:error, reason} when is_exception(reason) ->
          raise ArgumentError, "could not parse HTML with Meeseeks: #{Exception.message(reason)}"
      end
    end

    # Meeseeks wraps fragments in an <html> with <head> and <body> tags, so we
    # must unwrap it if the input was a fragment.
    defp unwrap_fragment(tree, html) do
      case Regex.match?(~r/<html/i, html) do
        true ->
          tree

        false ->
          # This may break if Meeseeks changes how it wraps fragments. If so,
          # move this into a function that handles different Meeseeks versions.
          [{"html", [], [{"head", [], head}, {"body", [], body}]}] = tree

          head ++ body
      end
    end

    @impl true
    @doc false
    def to_html(tree) do
      wrap_fragment(tree, fn tree ->
        tree
        |> Meeseeks.parse(:tuple_tree)
        |> Meeseeks.html()
      end)
    end

    @premailex_root "premailex-root"

    defp wrap_fragment(tree, fun) do
      case document?(tree) do
        true -> fun.(tree)
        false -> do_wrap_fragment(tree, fun)
      end
    end

    defp document?([]), do: false
    defp document?([{"html", _attrs, _children} | _]), do: true
    defp document?([_other | nodes]), do: document?(nodes)

    defp do_wrap_fragment(tree, fun) do
      html = fun.([{@premailex_root, [], tree}])
      [_, html] = Regex.run(~r/<#{@premailex_root}>(.*)<\/#{@premailex_root}>/s, html)

      html
    end
  end
end
