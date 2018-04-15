defmodule Premailex.HTMLParser.Floki do
  @moduledoc """
  API connection with Floki
  """

  @doc false
  @spec parse(String.t()) :: tuple
  def parse(html) do
    Floki.parse(html)
  end

  @doc false
  @spec all(tuple, String.t()) :: [tuple]
  def all(tree, selector) do
    Floki.find(tree, selector)
  end

  @doc false
  @spec to_string(tuple) :: String.t()
  def to_string(tree) do
    Floki.raw_html(tree)
  end
end
