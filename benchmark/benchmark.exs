defmodule Benchmark do
  @moduledoc """
  Minimal benchmarking utility for Premailex.
  """

  @doc """
  Runs a benchmark scenario.

  ## Options

    * `:extra_columns` - extra column definitions inserted between
      `nodes` and `time (ms)`, in the shape `{name, width,
      :left | :right}`;
  """
  def run!(cases, opts \\ []) do
    extra_columns = Keyword.get(opts, :extra_columns, [])

    columns =
      [{"name", name_column_width(cases), :left}, {"nodes", 7, :right}] ++
        extra_columns ++
        [{"time (ms)", 16, :right}]

    init!(columns)

    Enum.each(cases, fn {labels, run} ->
      {average, std_dev} = measure_time(fn -> run.() end)

      print_row(columns, labels ++ ["#{format_ms(average)} ± #{format_ms(std_dev)}"])
    end)
  end

  defp name_column_width(cases) do
    cases
    |> Enum.map(fn {[name | _rest], _run} ->
      String.length(name)
    end)
    |> Enum.max()
  end

  defp init!(columns) do
    html_parser = System.fetch_env!("HTML_PARSER")

    Application.put_env(
      :premailex,
      :html_parser,
      Module.concat(Premailex.HTMLParser, html_parser)
    )

    IO.puts("Benchmark with #{inspect(html_parser)} HTML parser:")
    IO.puts("")
    IO.puts(row(columns, Enum.map(columns, fn {name, _, _} -> name end)))
    IO.puts(divider(columns))
  end

  defp measure_time(fun, iterations \\ 20) do
    _warmup = fun.()

    times =
      for _ <- 1..iterations do
        {us, _} = :timer.tc(fun)
        us / 1_000
      end

    average = Enum.sum(times) / iterations

    variance =
      times
      |> Enum.map(&((&1 - average) * (&1 - average)))
      |> Enum.sum()
      |> Kernel./(iterations)

    {average, :math.sqrt(variance)}
  end

  defp print_row(columns, values), do: IO.puts(row(columns, values))

  defp format_ms(ms), do: :erlang.float_to_binary(ms, decimals: 2)

  defp row(columns, values) do
    columns
    |> Enum.zip(values)
    |> Enum.map(fn
      {{_name, width, :left}, value} -> String.pad_trailing(to_string(value), width)
      {{_name, width, :right}, value} -> String.pad_leading(to_string(value), width)
    end)
    |> Enum.intersperse("  ")
    |> then(&["  " | &1])
    |> IO.iodata_to_binary()
  end

  defp divider(columns) do
    values =
      Enum.map(columns, fn {_name, width, _align} ->
        String.duplicate("─", width)
      end)

    row(columns, values)
  end
end
