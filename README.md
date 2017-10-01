# Premailex

[![Build Status](https://travis-ci.org/danschultzer/premailex.svg?branch=master)](https://travis-ci.org/danschultzer/premailex)

Preflight for your HTML emails. Adds inline styling, and proper plain text alternative.

## Features

* Add inline CSS properties from `<style>` tags
* Transform HTML to plain text

## Installation

```elixir
def deps do
  [
    # ...
    {:premailex, github: "danschultzer/premailex"},
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

## Example with Bamboo

```elixir
defp email(email, template) do
  new_email()
  |> subject("Email subject")
  |> to("test@example.com")
  |> from("test@example.com")
  |> put_text_layout(false)
  |> render("email.html")
  |> premail()
end

defp premail(email) do
  email
  |> html_body(Premailex.to_inline_css(email.html_body))
  |> text_body(Premailex.to_text(email.html_body))
end
```

## Planned features

- Load `<link>` style tags
- Expand relative URL's

## LICENSE

(The MIT License)

Copyright (c) 2017 Dan Schultzer & the Contributors Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
