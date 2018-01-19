defmodule Premailex do
  @moduledoc """
  Documentation for Premailex.
  """

  @doc """
  Adds inline styles to an HTML string

  ## Examples

      iex> Premailex.to_inline_css("<html><head><style>p{background-color: #fff;}</style></head><body><p style=\\\"color: #000;\\\">Text</p></body></html>")
      "<html><head><style>p{background-color: #fff;}</style></head><body><p style=\\\"background-color:#fff;color:#000;\\\">Text</p></body></html>"

  """
  def to_inline_css(html) do
    Premailex.HTMLInlineStyles.process(html)
  end

  @doc """
  Turns an HTML string into text.

  ## Examples

      iex> Premailex.to_text("<html><head><style>p{background-color:#fff;}</style></head><body><p style=\\\"color:#000;\\\">Text</p></body></html>")
      "Text"

  """
  def to_text(html) do
    html
    |> Floki.find("body")
    |> Premailex.HTMLToPlainText.process()
  end
end
