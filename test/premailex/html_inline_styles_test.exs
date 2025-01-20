defmodule Premailex.HTMLInlineStylesTest do
  use ExUnit.Case
  doctest Premailex.HTMLInlineStyles

  alias ExUnit.CaptureLog

  @css_link_content """
  @charset "utf-8";

  html {color:black;}
  body,table,p,td,ul,ol {color:#333333; font-family:Arial, sans-serif; font-size:14px; line-height:22px;}

  h1, h2, h3, h4, p {margin: 0; padding: 0;}
  p:first-of-type {font-size:16px;font-weight:bold;}
  .invalid-empty-selector, {}
  """

  @css_inline_content """
  td p {color: red; font-size:13px; background-color:#fff;}
  p    {color: #000 !important; font-size:12px; background-color:#000;}

  a {color: #e95757; text-decoration: underline;}
  a:hover	{text-decoration: underline;}

  p.duplicate {color: blue;}
  .same-match {color:yellow;}
  """

  @input """
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
      <link href="http://localhost/styles.css" media="all" rel="stylesheet">
      <link media="all" rel="stylesheet">
      <title>Test</title>
      <style>#{@css_inline_content}</style>
    </head>
    <body>
    <table cellpadding="0" cellspacing="0" align="center" style="padding:20px; padding-top:0;">
      <tr>
        <td align="center">
          <p>First paragraph</p>
          <p><a href="#" style="color:#999999; font-size:12px;">Test link</a></p>
          <p class="duplicate">Testing duplicate</p>
        </td>
      </tr>
    </table>

    <table cellpadding="0" cellspacing="0" style="padding:20px;" align="center">
      <tr>
        <td>
          <table cellpadding="0" cellspacing="0" width="100%">
            <tr align="center">
              <td>
                <h1 style="font-size:24px; line-height:24px !important; padding-bottom:8px; color: #2eac6d;">Heading</h1>
                <p style="color: #fff;background-color:#fff !important;font-size:11px;"></p>
                <p class="duplicate">Testing duplicate</p>
                <p><span>Test</span> <span>consecutive</span> <span>tags</span></p>
              </td>
              <td align="right" valign="bottom"></td>
            </tr>
          </table>
        </td>
      </tr>
    </table>

    <!-- This is a comment -->

    <!--[if (gte mso 9)|(IE)]>
    <p>Downlevel-hidden comment</p>
    <![endif]-->

    <!--[if !mso]><!-- -->
    <p>Downlevel-revealed comment</p>
    <!--<![endif]-->

    <div class="match-order-test-1 same-match">
      <span class="same-match">1</span>
    </div>
    <div class="match-order-test-2 same-match">
      <span class="same-match">1</span>
    </div>
    <div class="match-order-test-3 same-match">
      <span class="same-match">1</span>
      <span class="same-match">2</span>
    </div>
    <div class="encapsulated">
      <div class="match-order-test-4 same-match">
        <span class="same-match">1</span>
      </div>
    </div>
    </body>
  </html>
  """

  setup context do
    input =
      case context[:test_server] do
        false ->
          @input

        _ ->
          TestServer.add("/styles.css",
            to: fn conn -> Plug.Conn.send_resp(conn, 200, @css_link_content) end
          )

          String.replace(@input, "http://localhost", TestServer.url())
      end

    {:ok, input: input}
  end

  test "process/3", %{input: input} do
    parsed = Premailex.HTMLInlineStyles.process(input)

    assert parsed =~ "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: black;\">"

    assert parsed =~
             "<body style=\"color: #333333; font-family: Arial, sans-serif; font-size: 14px; line-height: 22px;\">"

    assert parsed =~
             "<h1 style=\"color: #2eac6d; font-size: 24px; line-height: 24px !important; margin: 0; padding: 0; padding-bottom: 8px;\">"

    assert parsed =~
             "<p style=\"background-color: #fff; color: #000 !important; font-family: Arial, sans-serif; font-size: 16px; font-weight: bold; line-height: 22px; margin: 0; padding: 0;\">First paragraph"

    assert parsed =~
             "<p style=\"background-color: #fff; color: #000 !important; font-family: Arial, sans-serif; font-size: 13px; line-height: 22px; margin: 0; padding: 0;\">"

    # Ensure that whitespace is maintained when it would affect display
    assert parsed =~ "<span>Test</span> <span>consecutive</span> <span>tags</span>"

    refute parsed =~ "[SPEC="

    assert parsed =~ "<style>"
    assert parsed =~ "<link href"

    refute parsed =~ "This is a comment"

    assert parsed =~
             ~r/(#{Regex.escape("<!--[if (gte mso 9)|(IE)]>")})|(#{Regex.escape("<!-- [if (gte mso 9)|(IE)]>")})/

    assert parsed =~ "<p>Downlevel-hidden comment</p>"
    assert parsed =~ ~r/(#{Regex.escape("<![endif]-->")})|(#{Regex.escape("<![endif] -->")})/

    assert parsed =~
             ~r/(#{Regex.escape("<!--[if !mso]><!-- -->")})|(#{Regex.escape("<!-- [if !mso]><!--  -->")})/

    assert parsed =~
             "<p style=\"background-color: #000; color: #000 !important; font-family: Arial, sans-serif; font-size: 16px; font-weight: bold; line-height: 22px; margin: 0; padding: 0;\">Downlevel-revealed comment</p>"

    assert parsed =~
             ~r/(#{Regex.escape("<!--<![endif]-->")})|(#{Regex.escape("<!-- <![endif] -->")})/

    assert parsed =~ "<div class=\"match-order-test-1 same-match\" style=\"color: yellow;\">"
    assert parsed =~ "<div class=\"match-order-test-2 same-match\" style=\"color: yellow;\">"
    assert parsed =~ "<div class=\"match-order-test-3 same-match\" style=\"color: yellow;\">"
    assert parsed =~ "<div class=\"match-order-test-4 same-match\" style=\"color: yellow;\">"
  end

  @tag test_server: false
  test "process/3 when styles can't be loaded due to no network", %{input: input} do
    assert CaptureLog.capture_log(fn ->
             refute Premailex.HTMLInlineStyles.process(input) =~
                      "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: black;\">"
           end) =~
             "Ignoring http://localhost/styles.css styles because of unexpected error from Premailex.HTTPAdapter.Httpc:"
  end

  @tag test_server: false
  test "process/3 when styles can't be loaded due to 404", %{input: input} do
    TestServer.add("/styles.css", to: fn conn -> Plug.Conn.send_resp(conn, 404, "Not Found") end)
    input = String.replace(input, "http://localhost", TestServer.url())

    assert CaptureLog.capture_log(fn ->
             refute Premailex.HTMLInlineStyles.process(input) =~
                      "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: black;\">"
           end) =~
             "Ignoring #{TestServer.url()}/styles.css styles because received unexpected HTTP status: 404"
  end

  @tag test_server: false
  test "process/3 when styles can't be loaded due to SSL error", %{input: input} do
    TestServer.start(scheme: :https)
    input = String.replace(input, "http://localhost", TestServer.url())

    assert CaptureLog.capture_log(fn ->
             refute Premailex.HTMLInlineStyles.process(input) =~
                      "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: black;\">"
           end) =~ ":unknown_ca"
  end

  @tag test_server: false
  test "process/3 when styles loads on SSL", %{input: input} do
    TestServer.start(scheme: :https)

    TestServer.add("/styles.css",
      to: fn conn -> Plug.Conn.send_resp(conn, 200, @css_link_content) end
    )

    on_exit(fn ->
      Application.delete_env(:premailex, :http_adapter)
    end)

    ssl_opts =
      [
        verify: :verify_peer,
        depth: 99,
        cacerts: TestServer.x509_suite().cacerts,
        verify_fun: {&:ssl_verify_hostname.verify_fun/3, check_hostname: ~c"localhost"}
      ]

    Application.put_env(:premailex, :http_adapter, {Premailex.HTTPAdapter.Httpc, [ssl: ssl_opts]})
    input = String.replace(input, "http://localhost", TestServer.url())

    assert parsed = Premailex.HTMLInlineStyles.process(input)
    assert parsed =~ "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: black;\">"
  end

  test "process/3 with css_selector", %{input: input} do
    parsed =
      Premailex.HTMLInlineStyles.process(input, css_selector: "link[rel=\"stylesheet\"][href]")

    assert parsed =~
             "<p style=\"color: #333333; font-family: Arial, sans-serif; font-size: 16px; font-weight: bold; line-height: 22px; margin: 0; padding: 0;\">First paragraph"
  end

  test "process/3 with optimize: :all", %{input: input} do
    parsed = Premailex.HTMLInlineStyles.process(input, optimize: :all)
    refute parsed =~ "<style>"
    refute parsed =~ "<link href"
  end

  test "process/3 with optimize: :remove_style_tags", %{input: input} do
    parsed = Premailex.HTMLInlineStyles.process(input, optimize: :remove_style_tags)
    refute parsed =~ "<style>"
    refute parsed =~ "<link href"
  end

  test "process/3 with optimize: [:remove_style_tags]", %{input: input} do
    parsed = Premailex.HTMLInlineStyles.process(input, optimize: [:remove_style_tags])
    refute parsed =~ "<style>"
    refute parsed =~ "<link href"
  end

  test "process/3 with optimize: [:unknown]", %{input: input} do
    parsed = Premailex.HTMLInlineStyles.process(input, optimize: [:unknown])
    assert parsed =~ "<style>"
    assert parsed =~ "<link href"
  end

  test "process/3 with optimize: [:none]", %{input: input} do
    parsed = Premailex.HTMLInlineStyles.process(input, optimize: :none)
    assert parsed =~ "<style>"
    assert parsed =~ "<link href"
  end

  @tag test_server: false
  test "process/3 with no loaded styles" do
    parsed = Premailex.HTMLInlineStyles.process("<span style=\"width: 100%;\">Hello</span>")
    assert parsed =~ "<span style=\"width: 100%;\">Hello</span>"
  end

  test "process/3 accepts html tree as first argument", %{input: input} do
    html_tree = Premailex.HTMLParser.parse(input)
    parsed = Premailex.HTMLInlineStyles.process(html_tree)

    assert parsed =~ "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: black;\">"
    assert parsed =~ "<style>"
    assert parsed =~ "<link href"

    assert parsed =~
             "<body style=\"color: #333333; font-family: Arial, sans-serif; font-size: 14px; line-height: 22px;\">"
  end

  test "process/3 accepts html tree as first argument and options as second", %{input: input} do
    html_tree = Premailex.HTMLParser.parse(input)
    parsed = Premailex.HTMLInlineStyles.process(html_tree, optimize: :all)

    assert parsed =~ "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: black;\">"
    refute parsed =~ "<style>"
    refute parsed =~ "<link href"

    assert parsed =~
             "<body style=\"color: #333333; font-family: Arial, sans-serif; font-size: 14px; line-height: 22px;\">"
  end

  @tag test_server: false
  test "process/3 accepts css rule set as second argument", %{input: input} do
    css_rule_set = Premailex.CSSParser.parse("*{color:red;}")
    parsed = Premailex.HTMLInlineStyles.process(input, css_rule_set)

    assert parsed =~ "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: red;\">"
    assert parsed =~ "<style>"
    assert parsed =~ "<link href"
    assert parsed =~ "<body style=\"color: red;\">"

    css_rule_set = Premailex.CSSParser.parse("*{color:red;}")
    parsed = Premailex.HTMLInlineStyles.process(input, css_rule_set, optimize: :all)

    assert parsed =~ "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"color: red;\">"
    assert parsed =~ "<style>"
    assert parsed =~ "<link href"
    assert parsed =~ "<body style=\"color: red;\">"
  end
end
