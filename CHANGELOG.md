# Changelog

## v0.3.20 (2025-01-20)

* Require Elixir 1.13
* `Premailex.CSSParser.parse/1` now ignores empty selectors

## v0.3.19 (2023-11-19)

* Ignore `@charset` CSS at-rule

## v0.3.18 (2023-04-07)

* Fixed bug in `Premailex.HTMLToPlainText.parse/3` with `<thread>`, `<tbody>`, `<tfoot>` being excluded if the HTML element had any attributes

## v0.3.17 (2023-02-21)

* `Premailex.HTMLInlineStyles.process/3` now warns when styles can't be loaded from URL's
* `Premailex.HTMLInlineStyles.process/1` now parses `<thead>` and `<tfoot>` elements
* `Premailex.CSSParser.parse/1` now handles escaped commas
* Require Elixir 1.11

## v0.3.16 (2022-07-01)

* `Premailex.CSSParser.to_string/1` now adds whitespace between inline style rules

## v0.3.15 (2022-03-24)

* Fixed invalid spec in `Premailex.Util.traverse/3`

## v0.3.14 (2022-03-08)

* Added horizontal rule parsing to `Premailex.HTMLToPlainText.process/1`
* `Premailex.Util.traverse/3` no longer strips comments
* `Premailex.HTMLInlineStyles.process/3` strips empty comments
* `Premailex.HTMLInlineStyles.process/3` now applies styles to `<html>` elements

## v0.3.13 (2020-11-24)

* Fixed spec and docs issues.

## v0.3.12 (2020-10-18)

* `Premailex.HTMLInlineStyles.process/3` now supports passing in CSS as an argument

## v0.3.11 (2020-10-08)

* Fixed bug where the inline styles where applied to more than the first match causing in some cases styles to be missing for subsequent parent elements
* Relax floki requirement
* Relax meeseeks requirement

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

* Handle url values in CSS rules correctly #25

## v0.3.0

* Meeseeks `v0.8.0` no longer supported #23
* Ensure Elixir 1.7 support #22
