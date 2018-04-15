defmodule Premailex.HTMLParser.Meeseeks do
  @moduledoc """
  API connection with Meeseeks
  """

  import Meeseeks.CSS

  @doc false
  @spec parse(String.t()) :: tuple
  def parse(html) do
    html
    |> Meeseeks.parse()
    |> Meeseeks.tree()
    |> case do
      [html] -> html
      html -> html
    end
  end

  @doc false
  @spec all(tuple, String.t()) :: [tuple]
  def all(tree, selector) do
    tree
    |> Meeseeks.all(css("#{selector}"))
    |> Enum.map(&Meeseeks.tree/1)
  end

  @doc false
  @spec to_string(tuple) :: String.t()
  def to_string(tree) do
    tree
    |> Meeseeks.parse()
    |> Meeseeks.html()
  end
end
