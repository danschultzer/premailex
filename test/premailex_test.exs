defmodule PremailexTest do
  use ExUnit.Case
  doctest Premailex

  alias ExUnit.CaptureLog

  @external_css_content "html { color: black; }"

  @input """
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <link href="http://localhost/styles.css" rel="stylesheet">
      <link media="all" rel="stylesheet">
      <title>Test</title>
      <style>p { color: red; }</style>
    </head>
    <body>
      <p>Hello</p>
    </body>
  </html>
  """

  describe "to_inline_css/2" do
    setup :setup_external_css_endpoint

    test "applies inline styles", %{input: input} do
      parsed = Premailex.to_inline_css(input)

      assert parsed =~ ~s(<html xmlns="http://www.w3.org/1999/xhtml" style="color: black;">)
      assert parsed =~ ~s(<p style="color: red;">Hello</p>)
      assert parsed =~ "<style>"
      assert parsed =~ "<link href"
    end

    test "when external styles can't be loaded due to network error", %{input: input, url: url} do
      TestServer.HTTP.stop()

      assert CaptureLog.capture_log(fn ->
               refute Premailex.to_inline_css(input) =~ "color: black"
             end) =~
               "Ignoring #{url} styles due to error in Premailex.HTTPAdapter.Httpc:"
    end

    @tag external_css_response: {404, "Not Found"}
    test "when external styles can't be loaded due to 404", %{input: input} do
      assert CaptureLog.capture_log(fn ->
               refute Premailex.to_inline_css(input) =~ "color: black"
             end) =~
               "Ignoring #{TestServer.HTTP.url("/styles.css")} styles due to unexpected HTTP response status: 404"
    end

    @tag external_css_scheme: :https
    test "when external styles can't be loaded due to TLS error", %{input: input} do
      assert CaptureLog.capture_log(fn ->
               refute Premailex.to_inline_css(input) =~ "color: black"
             end) =~ ":unknown_ca"

      TestServer.HTTP.stop()
    end

    @tag external_css_scheme: :https
    test "when external styles loads with TLS", %{input: input} do
      http_adapter =
        {
          Premailex.HTTPAdapter.Httpc,
          [
            ssl: [
              verify: :verify_peer,
              depth: 99,
              cacerts: TestServer.HTTP.cacerts(),
              verify_fun: {&:ssl_verify_hostname.verify_fun/3, check_hostname: ~c"localhost"}
            ]
          ]
        }

      assert Premailex.to_inline_css(input, http_adapter: http_adapter) =~ "color: black"
    end

    test "with `:css_selector` option only loads matching sources", %{input: input} do
      parsed = Premailex.to_inline_css(input, css_selector: ~s(link[rel="stylesheet"][href]))

      assert parsed =~ ~s(<html xmlns="http://www.w3.org/1999/xhtml" style="color: black;">)
      refute parsed =~ ~s(<p style=)
    end

    test "with `remove_style_tags: true` option", %{input: input} do
      parsed = Premailex.to_inline_css(input, remove_style_tags: true)

      # Styles were applied before tag removal
      assert parsed =~ "color: black"
      # Source tags removed
      refute parsed =~ "<style>"
      refute parsed =~ "<link href"
    end
  end

  defp setup_external_css_endpoint(context) do
    context[:external_css_scheme] == :https && TestServer.HTTP.start(scheme: :https)
    {status, body} = context[:external_css_response] || {200, @external_css_content}

    TestServer.HTTP.handle("/styles.css",
      to: fn conn ->
        Plug.Conn.send_resp(conn, status, body)
      end
    )

    url = TestServer.HTTP.url("/styles.css")
    input = String.replace(@input, "http://localhost/styles.css", url)

    {:ok, input: input, url: url}
  end
end
