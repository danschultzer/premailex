defmodule Premailex.HTTPAdapter.Httpc do
  @moduledoc """
  HTTP adapter module for making http requests with httpc.

  SSL support will automatically be enabled if the `:certifi` and
  `:ssl_verify_fun` libraries exists in your project.
  """
  alias Premailex.{HTTPAdapter, HTTPAdapter.HTTPResponse}

  @behaviour HTTPAdapter

  @impl HTTPAdapter
  def request(method, url, body, headers, httpc_opts \\ nil) do
    headers = headers ++ [HTTPAdapter.user_agent_header()]
    request = httpc_request(url, body, headers)

    method
    |> :httpc.request(request, parse_httpc_opts(httpc_opts, url), [])
    |> format_response()
  end

  defp httpc_request(url, body, headers) do
    url = to_charlist(url)
    headers = Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)

    do_httpc_request(url, body, headers)
  end

  defp do_httpc_request(url, nil, headers) do
    {url, headers}
  end

  defp do_httpc_request(url, body, headers) do
    {content_type, headers} = split_content_type_headers(headers)
    body = to_charlist(body)

    {url, headers, content_type, body}
  end

  defp split_content_type_headers(headers) do
    case List.keytake(headers, 'content-type', 0) do
      nil -> {'text/plain', headers}
      {{_, ct}, headers} -> {ct, headers}
    end
  end

  defp format_response({:ok, {{_, status, _}, headers, body}}) do
    headers =
      Enum.map(headers, fn {key, value} -> {String.downcase(to_string(key)), to_string(value)} end)

    body = IO.iodata_to_binary(body)

    {:ok, %HTTPResponse{status: status, headers: headers, body: body}}
  end

  defp format_response({:error, error}), do: {:error, error}

  defp parse_httpc_opts(nil, url), do: default_httpc_opts(url)
  defp parse_httpc_opts(opts, _url), do: opts

  defp default_httpc_opts(url) do
    case certifi_and_ssl_verify_fun_available?() do
      true -> [ssl: ssl_opts(url)]
      false -> []
    end
  end

  defp certifi_and_ssl_verify_fun_available?() do
    Application.ensure_all_started(:certifi)
    Application.ensure_all_started(:ssl_verify_fun)

    app_available?(:certifi) && app_available?(:ssl_verify_fun)
  end

  defp app_available?(app) do
    case :application.get_key(app, :vsn) do
      {:ok, _vsn} -> true
      _ -> false
    end
  end

  defp ssl_opts(url) do
    %{host: host} = URI.parse(url)

    [
      verify: :verify_peer,
      depth: 99,
      cacerts: :certifi.cacerts(),
      verify_fun: {&:ssl_verify_hostname.verify_fun/3, check_hostname: to_charlist(host)}
    ]
  end
end
