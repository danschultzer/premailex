ExUnit.start()

if System.get_env("HTML_PARSER") == "meeseeks",
  do: Application.put_env(:premailex, :html_parser, Premailex.HTMLParser.Meeseeks)
