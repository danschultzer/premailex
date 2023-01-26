defmodule Premailex.CSSParser do
  @moduledoc """
  Module that handles CSS parsing with naive Regular Expression.
  """

  @type rule :: %{directive: String.t(), value: String.t(), important?: boolean}
  @type rule_set :: %{rules: [rule], selector: String.t(), specificity: number}

  @css_selector_rules ~r/([\s\S]*?){([\s\S]*?)}/mi

  @non_id_attributes_and_pseudo_classes ~r/
    (\.[\w]+)                     # classes
    |
    \[(\w+)                       # attributes
    |
    (\:(                          # pseudo classes
      link|visited|active
      |hover|focus
      |lang
      |target
      |enabled|disabled|checked|indeterminate
      |root
      |nth-child|nth-last-child|nth-of-type|nth-last-of-type
      |first-child|last-child|first-of-type|last-of-type
      |only-child|only-of-type
      |empty|contains
    ))
  /ix
  @elements_and_pseudo_elements ~r/
    ((^|[\s\+\>\~]+)[\w]+       # elements
    |
    \:{1,2}(                    # pseudo-elements
      after|before
      |first-letter|first-line
      |selection
    )
  )/ix
  @comments ~r/\/\*[\s\S]*?\*\//m
  @media_queries ~r/@media[^{]+{([\s\S]+?})\s*}/mi
  @font_face ~r/@font-face\s*{[\s\S]+?}/mi

  @doc """
  Parses a CSS string into a map.

  ## Examples

      iex> Premailex.CSSParser.parse("body { background-color: #fff !important; color: red; }")
      [%{rules: [%{directive: "background-color", value: "#fff !important", important?: true},
                 %{directive: "color", value: "red", important?: false}],
         selector: "body",
         specificity: 1}]
  """
  @spec parse(String.t()) :: [rule_set]
  def parse(""), do: []

  def parse(css) do
    @css_selector_rules
    |> Regex.scan(strip(css))
    |> Enum.map(&parse_selectors_rules(&1))
    |> Enum.reduce([], &Enum.concat(&2, &1))
  end

  defp parse_selectors_rules([_, selector, rules]) do
    selector
    # Ignore escaped commas
    |> String.split(~r/(?<!\\),/)
    |> Enum.map(&parse_selector_rules(&1, rules))
  end

  defp parse_selector_rules(selector, rules) do
    %{
      selector: String.trim(selector),
      rules: parse_rules(rules),
      specificity: calculate_specificity(selector)
    }
  end

  @doc """
  Parses a CSS rules string into a map.

  Note: `parse_rules/1` won't strip any CSS comments unlike `parse/1`.

  ## Examples

      iex> Premailex.CSSParser.parse_rules("background-color: #fff; color: red;")
      [%{directive: "background-color", value: "#fff", important?: false},
       %{directive: "color", value: "red", important?: false}]
  """
  @spec parse_rules(String.t()) :: [rule]
  def parse_rules(rules) do
    rules
    |> String.split(";")
    |> Enum.map(&parse_rule(&1))
    |> Enum.filter(&(!is_nil(&1)))
  end

  defp parse_rule(rule) when is_binary(rule) do
    rule
    |> String.trim()
    |> String.split(":", parts: 2)
    |> parse_rule()
  end

  defp parse_rule([directive, value]) do
    %{
      directive: String.trim(directive),
      value: String.trim(value),
      important?: String.contains?(value, "!important")
    }
  end

  defp parse_rule([""]), do: nil

  defp parse_rule([value]) do
    %{
      directive: "",
      value: String.trim(value),
      important?: String.contains?(value, "!important")
    }
  end

  defp strip(string) do
    string
    |> String.replace(@font_face, "")
    |> String.replace(@media_queries, "")
    |> String.replace(@comments, "")
  end

  @doc """
  Merges CSS rules.

  ## Examples

      iex> rule_sets = Premailex.CSSParser.parse("p {background-color: #fff !important; color: #000;} p {background-color: #000;}")
      iex> Premailex.CSSParser.merge(rule_sets)
      [%{directive: "background-color", value: "#fff !important", important?: true, specificity: 1},
       %{directive: "color", value: "#000", important?: false, specificity: 1}]
  """
  @spec merge([rule_set]) :: [rule_set]
  def merge(rule_sets) do
    rule_sets
    |> Enum.map(fn rule_set ->
      Enum.map(rule_set.rules, &Map.put(&1, :specificity, rule_set.specificity))
    end)
    |> Enum.reduce([], &Enum.concat(&2, &1))
    |> merge_rule_sets
  end

  defp merge_rule_sets(rule_sets) do
    rule_sets
    |> Enum.reduce(%{}, &merge_into_rule_set(&2, &1))
    |> Enum.into([], &elem(&1, 1))
  end

  defp merge_into_rule_set(rule_set, new_rule) do
    rule = rule_set |> Map.get(new_rule.directive, nil)

    # Cascading order: http://www.w3.org/TR/CSS21/cascade.html#cascading-order
    cond do
      is_nil(rule) ->
        Map.put(rule_set, new_rule.directive, new_rule)

      new_rule.important? and (!rule.important? or rule.specificity <= new_rule.specificity) ->
        Map.put(rule_set, new_rule.directive, new_rule)

      !rule.important? and rule.specificity <= new_rule.specificity ->
        Map.put(rule_set, new_rule.directive, new_rule)

      true ->
        rule_set
    end
  end

  @doc """
  Transforms CSS map or list into string.

  ## Examples

      iex> Premailex.CSSParser.to_string([%{directive: "background-color", value: "#fff"}, %{directive: "color", value: "#000"}])
      "background-color: #fff; color: #000;"

      iex> Premailex.CSSParser.to_string(%{directive: "background-color", value: "#fff"})
      "background-color: #fff;"
  """
  @spec to_string([rule]) :: String.t()
  def to_string(rules) when is_list(rules) do
    Enum.map_join(rules, " ", &__MODULE__.to_string/1)
  end

  def to_string(%{directive: directive, value: value}), do: "#{directive}: #{value};"

  defp calculate_specificity(selector) do
    b = ~r/\#/ |> Regex.scan(selector) |> length()
    c = @non_id_attributes_and_pseudo_classes |> Regex.scan(selector) |> length()
    d = @elements_and_pseudo_elements |> Regex.scan(selector) |> length()

    b + c + d
  end
end
