defmodule Premailex.HTTPoisonAdapter do
  @moduledoc """
  Adapter module for HTTPoison.
  """
  alias HTTPoison.Response

  @httpoison_opts [follow_redirect: true]

  @doc """
  Fetches an URL and returns the body if the response has a 200 HTTP status
  code.

  ## Examples

      iex> Premailex.HTTPoisonAdapter.get("http://localhost:4000/styles.css")
      {:ok, "body {color: #000;}"}

      iex> Premailex.HTTPoisonAdapter.get("http://localhost:4000/nonexistant.css")
      {:error, %HTTPoison.Response{status_code: 404}}

  """
  @spec get(String.t()) :: {:ok, String.t()} | {:error, term()}
  def get(url) do
    url
    |> HTTPoison.get([], @httpoison_opts)
    |> process()
  end

  defp process({:ok, %Response{status_code: 200, body: body}}), do: {:ok, body}
  defp process({:ok, resp}), do: {:error, resp}
  defp process(any), do: any
end
