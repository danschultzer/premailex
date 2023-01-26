defmodule Premailex.CSSParserTest do
  use ExUnit.Case
  doctest Premailex.CSSParser

  @input """
  body, table {/* text-decoration:underline */background-color:#ffffff;background-image:url('http://example.com/image.png');color:#000000;}
  div p > a:hover {color:#000000 !important;text-decoration:underline}
  /*div {
    padding:10px
  }*/
  @media screen and (max-width: 600px) {
    body {
      width: auto;
    }
  }
  @font-face {
    font-family: "Open Sans";
    src: url("/fonts/OpenSans-Regular-webfont.woff2") format("woff2"),
         url("/fonts/OpenSans-Regular-webfont.woff") format("woff");
  }
  .with\\,escaped\\,commas {}
  """

  @parsed [
    %{
      rules: [
        %{directive: "background-color", value: "#ffffff", important?: false},
        %{
          directive: "background-image",
          value: "url('http://example.com/image.png')",
          important?: false
        },
        %{directive: "color", value: "#000000", important?: false}
      ],
      selector: "body",
      specificity: 1
    },
    %{
      rules: [
        %{directive: "background-color", value: "#ffffff", important?: false},
        %{
          directive: "background-image",
          value: "url('http://example.com/image.png')",
          important?: false
        },
        %{directive: "color", value: "#000000", important?: false}
      ],
      selector: "table",
      specificity: 1
    },
    %{
      rules: [
        %{directive: "color", value: "#000000 !important", important?: true},
        %{directive: "text-decoration", value: "underline", important?: false}
      ],
      selector: "div p > a:hover",
      specificity: 4
    },
    %{
      rules: [],
      selector: ".with\\,escaped\\,commas",
      specificity: 1
    }
  ]

  test "parse/1" do
    assert Premailex.CSSParser.parse(@input) == @parsed
  end
end
