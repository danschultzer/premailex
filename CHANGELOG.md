# Changelog

## v0.3.10 (TBA)

* Fixed bug where the inline styles where applied to more than the first match causing in some cases styles to be missing for subsequent parent elements

## v0.3.10 (2020-01-09)

* Support floki up to `v0.24.x`

## v0.3.9 (2019-10-06)

* Ignore `@font-face` at-rule

## v0.3.8 (2019-08-22)

* Removed HTTPoison and use `:httpc` instead
* Fixed bug where HTML with no style tags resulted in all existing inline styles being removed
* Added `is_binary/1` guard to `Premailex.to_inline_css/2` and `Premailex.to_text/1`

## v0.3.7 (2019-07-05)

* Preserve downlevel-revealed conditional comments in `Premailex.Util.traverse/3`

## v0.3.6 (2019-06-22)

* Preserve conditional comments in `Premailex.Util.traverse/3` so they can show up in output from `Premailex.HTMLInlineStyles.process/2`

## v0.3.5 (2019-03-21)

* Accept `<table>` with `<th>` elements.

## v0.3.4

* HTTP adapter for HTTPoison that handles redirects #31 #32 (thanks Przemyslaw Mroczek @Lackoftactics)

## v0.3.3

* Ignore `@media` queries  #28 #29

## v0.3.2

* Remove bypass for tests and make http adapter configurable #27
* Test with updated dependencies #26

## v0.3.1

* Handle url values in css rules correctly #25

## v0.3.0

* Meeseeks `v0.8.0` no longer supported #23
* Ensure Elixir 1.7 support #22
