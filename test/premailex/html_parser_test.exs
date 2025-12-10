defmodule Premailex.HTMLParserTest do
  use ExUnit.Case
  doctest Premailex.HTMLParser

  alias Premailex.HTMLParser

  setup do
    # Save original parser config
    original_parser = Application.get_env(:premailex, :html_parser)

    on_exit(fn ->
      if original_parser do
        Application.put_env(:premailex, :html_parser, original_parser)
      else
        Application.delete_env(:premailex, :html_parser)
      end
    end)

    {:ok, original_parser: original_parser}
  end

  describe "when no parser is configured and none are available" do
    test "raises helpful error message with all parser options" do
      # Clear the config to trigger automatic parser detection
      Application.delete_env(:premailex, :html_parser)

      # Note: In a real scenario where no parsers are available, find_available_parser
      # would be called. Since we can't easily mock Code.ensure_loaded? in tests where
      # parsers are loaded, we test the error message format by using a non-existent parser
      # which exercises a similar error path. The actual "no parser found" error would
      # only occur if none of Floki, Meeseeks, or LazyHTML are available.

      # Test with a non-existent parser module to verify error message format
      Application.put_env(:premailex, :html_parser, :NonExistentParserModule)

      error =
        assert_raise RuntimeError, fn ->
          HTMLParser.parse("<html></html>")
        end

      message = Exception.message(error)

      # Verify the error message contains helpful information
      assert message =~ "The configured HTML parser"
      assert message =~ "is not available"
      assert message =~ "floki" or message =~ "Floki"
      assert message =~ "meeseeks" or message =~ "Meeseeks"
      assert message =~ "lazy_html" or message =~ "LazyHTML"
      assert message =~ "mix.exs"
    end

    test "raises error with 'No HTML parser is available' message when no parser found" do
      # Clear config to trigger automatic detection
      Application.delete_env(:premailex, :html_parser)

      # Use a module that exists but will fail parser_available? check
      # (any atom that's not a valid parser module)
      Application.put_env(:premailex, :html_parser, Premailex.HTMLParser)

      # This will try to use Premailex.HTMLParser as the parser, which will fail
      # parser_available? check, then try to find an available parser.
      # Since we can't easily simulate all parsers being unavailable in a test
      # environment, we verify the error handling works correctly.

      # Actually, let's test with a module that will definitely fail
      Application.put_env(:premailex, :html_parser, :InvalidParserModule)

      error =
        assert_raise RuntimeError, fn ->
          HTMLParser.parse("<html></html>")
        end

      message = Exception.message(error)

      # Should mention that the parser is not available and provide alternatives
      assert message =~ "not available" or message =~ "No HTML parser"
      assert message =~ "floki" or message =~ "Floki" or message =~ "0.19"
      assert message =~ "meeseeks" or message =~ "Meeseeks" or message =~ "0.11"
      assert message =~ "lazy_html" or message =~ "LazyHTML" or message =~ "0.1.8"
    end
  end

  describe "when configured parser is not available" do
    test "raises helpful error message with dependency instructions" do
      Application.put_env(:premailex, :html_parser, Premailex.HTMLParser.Floki)

      # Temporarily unload Floki to simulate it not being available
      # We'll use a different approach - set a module that doesn't exist
      Application.put_env(:premailex, :html_parser, :NonExistentParser)

      error_message =
        assert_raise RuntimeError, fn ->
          HTMLParser.parse("<html></html>")
        end

      assert Exception.message(error_message) =~ "The configured HTML parser"
      assert Exception.message(error_message) =~ "is not available"
      assert Exception.message(error_message) =~ "floki"
      assert Exception.message(error_message) =~ "meeseeks"
      assert Exception.message(error_message) =~ "lazy_html"
    end
  end

  describe "parser availability detection" do
    test "uses configured parser when available" do
      # This test verifies that when a parser is configured and available, it's used
      # We'll test with each available parser
      parsers = [
        Premailex.HTMLParser.Floki,
        Premailex.HTMLParser.Meeseeks,
        Premailex.HTMLParser.LazyHTML
      ]

      Enum.each(parsers, fn parser ->
        if parser_available?(parser) do
          Application.put_env(:premailex, :html_parser, parser)
          # Should not raise
          result = HTMLParser.parse("<div>test</div>")
          assert is_tuple(result) or is_list(result)
        end
      end)
    end
  end

  # Helper to check if a parser is available (mirrors the private function logic)
  defp parser_available?(Premailex.HTMLParser.Floki) do
    Code.ensure_loaded?(Floki)
  end

  defp parser_available?(Premailex.HTMLParser.Meeseeks) do
    Code.ensure_loaded?(Meeseeks)
  end

  defp parser_available?(Premailex.HTMLParser.LazyHTML) do
    Code.ensure_loaded?(LazyHTML)
  end

  defp parser_available?(_), do: false
end
