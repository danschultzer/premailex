# Changelog

## Unreleased

### Bug fixes

* `Premailex.HTMLParser.Meeseeks.parse/1` no longer raises `MatchError` for document fragments that contains head level content such as `<style>`, `<meta>`, `<link>`, or `<title>`
* `Premailex.DOM.traverse_with_matching_items/3` now passes matching selector items to the callback in the order they were given in, so declarations of equal specificity are again resolved by source order

## v1.0.0 (2026-05-24)

Requires Elixir 1.15 or higher.

This release contains significant performance improvements, with typical HTML emails seeing a 30x+ speedup when inlining styles. Premailex is also now zero dependency thanks to the new fallback HTML parser `Premailex.HTMLParser.Xmerl`.

### Architecture changes

The layers between parser, DOM operations, and the top-level API have been reshaped:

* `Premailex.HTMLParser` is now a thin behaviour with only `c:Premailex.HTMLParser.parse/1` and `c:Premailex.HTMLParser.to_html/1` callbacks
* `Premailex.DOM` is a new module that handles all selector matching, traversal, and tree manipulation
* `Premailex.Util` has been removed with functions moved into `Premailex.DOM`
* `Premailex.HTMLInlineStyles.process/2` is now a pure tree to tree transformation that accepts an explicit list of CSS rules

### Breaking changes

* `Premailex.HTMLInlineStyles.process/3` no longer exposed, use `Premailex.HTMLInlineStyles.process/2`
* `Premailex.HTMLToPlainText.process/1` no longer accepts HTML string
* `Premailex.HTMLParser` behaviour callback `to_string` renamed to `to_html`
* `Premailex.HTMLParser` behaviour no longer requires `all`, `filter`, or `text` callbacks
* `Premailex.HTMLParser` no longer exposes `parse`, use `Premailex.parse/2` instead
* `Premailex.HTMLParser` no longer exposes `to_string`, use `Premailex.to_html/2` instead
* `Premailex.HTMLParser` no longer exposes `all`, use `Premailex.DOM.all/2` instead
* `Premailex.HTMLParser` no longer exposes `filter`, use `Premailex.DOM.reject/2` instead
* `Premailex.HTMLParser` no longer exposes `text`, use `Premailex.DOM.text_content/1` instead
* `Premailex.Util` has been removed:
  * `Premailex.Util.traverse/3` is now `Premailex.DOM.replace_all_matches/3`
  * `Premailex.Util.traverse_until_first/3` is now `Premailex.DOM.replace_first_match/3`
  * `Premailex.Util.traverse_reduce/3` is removed, use `Premailex.DOM.traverse_with_matching_items/3` for indexed single-walk updates
* Renamed `Premailex.CSSParser.parse_rules/1` to `Premailex.CSSParser.parse_declaration_block/1`
* Renamed `Premailex.CSSParser.merge/1` to `Premailex.CSSParser.cascade/1`
* `c:Premailex.HTTPAdapter.request/5` callback no longer requires the `Premailex.HTTPAdapter.HTTPResponse` struct in favor of using a map
* `Premailex.parse/2` now always returns a list
* `Floki` minimum version bumped from `~> 0.19` to `~> 0.24`
* `Premailex.to_inline_css/2` `:optimize` option has been replaced by a single boolean option `:remove_style_tags`

### Additions

* Added `Premailex.parse/2` and `Premailex.to_html/2`
* Added support for `LazyHTML`
* Added fallback support for `:xmerl`
* Added `Premailex.CSSParser.split_selector_groups/1` for selector group splitting
* Added `Premailex.DOM.traverse_with_matching_items/3` for indexed single-walk tree updates
* Added support for structural pseudo-classes: `:first-child`, `:last-child`, `:only-child`, `:last-of-type`, `:only-of-type`, `:nth-child`, `:nth-of-type`, `:nth-last-child`, `:nth-last-of-type`, `:empty`, `:root` (`An+B`, `odd`, and `even` arguments supported)

### Other

* `Floki` is now optional
* `Premailex.CSSParser` rewritten and no longer uses regular expressions to parse CSS
* `Premailex.CSSParser.parse_declaration_block/1` now does case insensitive, terminal `!important` detection
* `Premailex.HTMLInlineStyles.process/2` tree traversal performance changed from O(N^2) to O(N)
* Fixed compiler warnings in `Premailex.HTMLParser.Meeseeks`
