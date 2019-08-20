defmodule Premailex do
  @moduledoc """
  Documentation for Premailex.
  """

  alias Premailex.HTMLParser

  @doc """
  Adds inline styles to an HTML string.

  ## Examples

      iex> Premailex.to_inline_css("<html><head><style>p{background-color: #fff;}</style></head><body><p style=\\\"color: #000;\\\">Text</p></body></html>")
      "<html><head><style>p{background-color: #fff;}</style></head><body><p style=\\\"background-color:#fff;color:#000;\\\">Text</p></body></html>"

  """
  @spec to_inline_css(String.t(), Keyword.t()) :: String.t()
  def to_inline_css(html, options \\ []) when is_binary(html) do
    Premailex.HTMLInlineStyles.process(html, options)
  end

  @doc """
  Turns an HTML string into text.

  ## Examples

      iex> Premailex.to_text("<html><head><style>p{background-color:#fff;}</style></head><body><p style=\\\"color:#000;\\\">Text</p></body></html>")
      "Text"

  """
  @spec to_text(String.t()) :: String.t()
  def to_text(html) when is_binary(html) do
    html
    |> HTMLParser.parse()
    |> HTMLParser.all("body")
    |> Premailex.HTMLToPlainText.process()
  end
end
