defmodule Premailex.HTMLInlineStylesTest do
  use ExUnit.Case
  doctest Premailex.HTMLInlineStyles

  alias ExUnit.CaptureLog
  alias Premailex.{CSSParser, HTMLInlineStyles}

  @css_sources [
    """
    @charset "utf-8";

    html {color:black;}
    body,table,p,td,ul,ol {color:#333333; font-family:Arial, sans-serif; font-size:14px; line-height:22px;}

    h1, h2, h3, h4, p {margin: 0; padding: 0;}
    p:first-of-type {font-size:16px;font-weight:bold;}
    .invalid-empty-selector, {}
    """,
    """
    td p {color: red; font-size:13px; background-color:#fff;}
    p    {color: #000 !important; font-size:12px; background-color:#000;}

    a {color: #e95757; text-decoration: underline;}
    a:hover	{text-decoration: underline;}

    p.duplicate {color: blue;}
    .same-match {color:yellow;}
    """
  ]

  @input """
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
      <title>Test</title>
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

  describe "process/2" do
    test "applies CSS rules" do
      css_rules = Enum.flat_map(@css_sources, &Premailex.CSSParser.parse/1)
      tree = Premailex.parse(@input)

      {parsed, log} =
        CaptureLog.with_log(fn ->
          tree
          |> HTMLInlineStyles.process(css_rules)
          |> Premailex.to_html()
        end)

      assert log =~ "Pseudo-class :hover is not implemented. Ignoring."

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

    test "with css with higher specificity rule last" do
      tree = Premailex.parse(~s(<p class="lead">Text</p>))
      css_rules = CSSParser.parse("p { color: red; } p.lead { color: blue; }")

      assert tree
             |> HTMLInlineStyles.process(css_rules)
             |> Premailex.to_html() == ~s(<p class="lead" style="color: blue;">Text</p>)
    end

    test "with equal specificity rules resolves by source order" do
      tree = Premailex.parse(~s(<p class="a b">Text</p>))

      assert tree
             |> HTMLInlineStyles.process(
               CSSParser.parse(".a { color: red; } .b { color: blue; }")
             )
             |> Premailex.to_html() == ~s(<p class="a b" style="color: blue;">Text</p>)

      assert tree
             |> HTMLInlineStyles.process(
               CSSParser.parse(".b { color: blue; } .a { color: red; }")
             )
             |> Premailex.to_html() == ~s(<p class="a b" style="color: red;">Text</p>)
    end

    test "with equal specificity rules ignores the order of the class attribute" do
      css_rules = CSSParser.parse(".a { color: red; } .b { color: blue; }")

      assert ~s(<p class="a b">Text</p>)
             |> Premailex.parse()
             |> HTMLInlineStyles.process(css_rules)
             |> Premailex.to_html() == ~s(<p class="a b" style="color: blue;">Text</p>)

      assert ~s(<p class="b a">Text</p>)
             |> Premailex.parse()
             |> HTMLInlineStyles.process(css_rules)
             |> Premailex.to_html() == ~s(<p class="b a" style="color: blue;">Text</p>)
    end

    test "with duplicate selector resolves by source order" do
      tree = Premailex.parse(~s(<p class="a">Text</p>))

      assert tree
             |> HTMLInlineStyles.process(
               CSSParser.parse(".a { color: red; } .a { color: blue; }")
             )
             |> Premailex.to_html() == ~s(<p class="a" style="color: blue;">Text</p>)
    end

    test "with equal specificity rules in different selector types" do
      # `.a` is matched by class and `[data-x]` by the universal bucket, both
      # with a specificity of {0, 0, 1, 0}
      tree = Premailex.parse(~s(<p class="a" data-x="1">Text</p>))

      assert tree
             |> HTMLInlineStyles.process(
               CSSParser.parse(".a { color: red; } [data-x] { color: blue; }")
             )
             |> Premailex.to_html() == ~s(<p class="a" data-x="1" style="color: blue;">Text</p>)

      assert tree
             |> HTMLInlineStyles.process(
               CSSParser.parse("[data-x] { color: blue; } .a { color: red; }")
             )
             |> Premailex.to_html() == ~s(<p class="a" data-x="1" style="color: red;">Text</p>)
    end

    test "with higher specificity rule first takes precedence over source order" do
      tree = Premailex.parse(~s(<p class="a b">Text</p>))

      assert tree
             |> HTMLInlineStyles.process(
               CSSParser.parse("p.a { color: red; } .b { color: blue; }")
             )
             |> Premailex.to_html() == ~s(<p class="a b" style="color: red;">Text</p>)
    end

    test "with wildcard rule" do
      tree =
        Premailex.parse("""
        <html><head>
            <title>Page</title>
          </head>
          <body>
            <p>Text</p>
        </body></html>\
        """)

      assert tree
             |> HTMLInlineStyles.process(CSSParser.parse("* { color: red; }"))
             |> Premailex.to_html() ==
               """
               <html style="color: red;"><head>
                   <title>Page</title>
                 </head>
                 <body style="color: red;">
                   <p style="color: red;">Text</p>
               </body></html>\
               """
    end
  end
end
