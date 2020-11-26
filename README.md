# Premailex

[![Build Status](https://travis-ci.org/danschultzer/premailex.svg?branch=master)](https://travis-ci.org/danschultzer/premailex)
[![Module Version](https://img.shields.io/hexpm/v/premailex.svg)](https://hex.pm/packages/premailex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/premailex/)
[![Total Download](https://img.shields.io/hexpm/dt/premailex.svg)](https://hex.pm/packages/premailex)
[![License](https://img.shields.io/hexpm/l/premailex.svg)](https://github.com/danschultzer/premailex/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/danschultzer/premailex.svg)](https://github.com/danschultzer/premailex/commits/master)

Preflight for your HTML emails. Adds inline styling, and converts HTML to plain text.

## Features

* Add inline CSS properties from `<style>`
* Add inline CSS properties from external `<link>` stylesheets
* Transform HTML to plain text

## Installation

```elixir
def deps do
  [
    # ...
    {:premailex, "~> 0.3.0"},

    # Optional, but recommended for SSL validation with :httpc
    {:certifi, "~> 2.4"},
    {:ssl_verify_fun, "~> 1.1"},
    # ...
  ]
end
```

Run `mix deps.get` to install it.

## Getting started

Transform an HTML string to text:

```elixir
Premailex.to_text(html)
```

Add inline styles based on styles defined in `<head>`:

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

By default, premailex uses [`Floki`](https://github.com/philss/floki) to parse HTML, but you can exchange it for any HTML parser you prefer. [`Meeseeks`](https://github.com/mischov/meeseeks) is supported with the [`Premailex.HTMLParser.Meeseeks`](/lib/premailex/html_parser/meeseeks.ex) module. To use it, add the following to `config.exs`:

```elixir
config :premailex, html_parser: Premailex.HTMLParser.Meeseeks
```

## Planned features

- Expand relative URL's

## LICENSE

(The MIT License)

Copyright (c) 2017-present Dan Schultzer & the Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
