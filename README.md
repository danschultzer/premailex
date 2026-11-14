# Premailex

[![hex.pm](https://img.shields.io/hexpm/v/premailex.svg?style=flat)](https://hex.pm/packages/premailex) [![hex.pm downloads](https://img.shields.io/hexpm/dt/premailex.svg?style=flat)](https://hex.pm/packages/premailex) [![GitHub CI](https://github.com/danschultzer/premailex/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/danschultzer/premailex/actions?query=workflow%3ACI)

<!-- MDOC !-->

Preflight for your HTML emails. Inlines CSS styles and converts HTML to plain text.

## Features

* Inline CSS from `<style>` tags
* Inline CSS from external `<link>` stylesheets
* Convert HTML to plain text

## Usage

Convert an HTML string to plain text:

```elixir
Premailex.to_text(html)
```

Inline an HTML string with CSS styles defined in `<head>`:

```elixir
Premailex.to_inline_css(html)
```

## Example with Swoosh

```elixir
def welcome(user) do
  new()
  |> to({user.name, user.email})
  |> from({"Dr B Banner", "hulk.smash@example.com"})
  |> subject("Hello, Avengers!")
  |> render_body("welcome.html", %{username: user.username})
  |> premail()
end

defp premail(email) do
  html = Premailex.to_inline_css(email.html_body)
  text = Premailex.to_text(email.html_body)

  email
  |> html_body(html)
  |> text_body(text)
end
```

## Example with Bamboo

```elixir
def welcome_email do
  new_email
  |> subject("Email subject")
  |> to("test@example.com")
  |> from("test@example.com")
  |> put_text_layout(false)
  |> render("email.html")
  |> premail()
end

defp premail(email) do
  html = Premailex.to_inline_css(email.html_body)
  text = Premailex.to_text(email.html_body)

  email
  |> html_body(html)
  |> text_body(text)
end
```

## HTML parser

Premailex supports [`LazyHTML`](https://github.com/dashbitco/lazy_html), [`Floki`](https://github.com/philss/floki), [`Meeseeks`](https://github.com/mischov/meeseeks), and [`:xmerl`](https://www.erlang.org/doc/apps/xmerl/xmerl_ug.html).

It automatically selects the first available parser based on your `mix.exs` dependencies:

```elixir
defp deps do
  [
    {:premailex, "~> 1.0"},
    # {:lazy_html, "~> 0.1.11"},
    # {:floki, "~> 0.24"},
    # {:meeseeks, "~> 0.11"}
  ]
end
```

To explicitly configure which parser to use, add to your `config.exs`:

```elixir
config :premailex, html_parser: Premailex.HTMLParser.Meeseeks
# or
config :premailex, html_parser: Premailex.HTMLParser.LazyHTML
```

<!-- MDOC !-->

## Installation

```elixir
def deps do
  [
    # ...
    {:premailex, "~> 1.0"},

    # Optional, but recommended for SSL validation with :httpc
    {:certifi, "~> 2.4"},
    {:ssl_verify_fun, "~> 1.1"},
    # ...
  ]
end
```

Remember to run `mix deps.get` to install the dependencies.

## LICENSE

(The MIT License)

Copyright (c) 2017 Dan Schultzer & the Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
