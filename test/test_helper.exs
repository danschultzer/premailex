ExUnit.start()

cond do
  System.get_env("HTML_PARSER") == "meeseeks" ->
    Application.put_env(:premailex, :html_parser, Premailex.HTMLParser.Meeseeks)

  System.get_env("HTML_PARSER") == "lazy_html" ->
    Application.put_env(:premailex, :html_parser, Premailex.HTMLParser.LazyHTML)

  true ->
    :ok
end
