defmodule Premailex.HTMLInlineStylesTest do
  use ExUnit.Case
  doctest Premailex.HTMLInlineStyles

  @css_link_content """
  body,table,p,td,ul,ol {color:#333333; font-family:Arial, sans-serif; font-size:14px; line-height:22px;}

  h1, h2, h3, h4, p {margin: 0; padding: 0;}
  p:first-of-type {font-size:16px;font-weight:bold;}
  """

  @css_inline_content """
  td p {color: red; font-size:13px; background-color:#fff;}
  p    {color: #000 !important; font-size:12px; background-color:#000;}

  a {color: #e95757; text-decoration: underline;}
  a:hover	{text-decoration: underline;}

  p.duplicate {color: blue;}
  """

  @input """
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
      <link href="STYLESHEET_URL" media="all" rel="stylesheet">
      <link href="INVALID_URL" media="all" rel="stylesheet">
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
                <p><span>consecutive</span> <span>tags</span></p>
              </td>
              <td align="right" valign="bottom"></td>
            </tr>
          </table>
        </td>
      </tr>
    </body>
  </html>
  """

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "parse to text", %{bypass: bypass} do
    input =
      @input
      |> String.replace("STYLESHEET_URL", "http://localhost:#{bypass.port}/styles.css")
      |> String.replace("INVALID_URL", "http://localhost:#{bypass.port}/invalid_styles.css")

    Bypass.expect_once(bypass, "GET", "/styles.css", fn conn ->
      Plug.Conn.resp(conn, 200, @css_link_content)
    end)

    Bypass.expect_once(bypass, "GET", "/invalid_styles.css", fn conn ->
      Plug.Conn.resp(conn, 500, "{}")
    end)

    parsed = Premailex.HTMLInlineStyles.process(input, "style,link[rel=\"stylesheet\"][href]")

    # Ensure the doctype is retained
    assert parsed =~
             "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"

    assert parsed =~
             "<body style=\"color:#333333;font-family:Arial, sans-serif;font-size:14px;line-height:22px;\">"

    assert parsed =~
             "<h1 style=\"color:#2eac6d;font-size:24px;line-height:24px !important;margin:0;padding:0;padding-bottom:8px;\">"

    assert parsed =~
             "<p style=\"background-color:#fff;color:#000 !important;font-family:Arial, sans-serif;font-size:16px;font-weight:bold;line-height:22px;margin:0;padding:0;\">First paragraph"

    assert parsed =~
             "<p style=\"background-color:#fff;color:#000 !important;font-family:Arial, sans-serif;font-size:13px;line-height:22px;margin:0;padding:0;\">"

    # Ensure that whitespace is maintained when it would affect display
    assert parsed =~
             "<span>consecutive</span> <span>tags</span>"

    # Ensure that after inlining, stylesheets are removed
    refute parsed =~
             "<style>"
    refute parsed =~
             "<link href="

    refute parsed =~ "[SPEC="
  end
end
