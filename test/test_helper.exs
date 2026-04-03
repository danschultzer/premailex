ExUnit.start()

html_parser = System.get_env("HTML_PARSER", "Floki")
html_parser = Module.concat(Premailex.HTMLParser, html_parser)

Application.put_env(:premailex, :html_parser, html_parser)

IO.puts("Testing with #{inspect(html_parser)}")
