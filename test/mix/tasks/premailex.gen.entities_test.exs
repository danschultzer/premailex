if Code.ensure_loaded?(JSON) do
  defmodule Mix.Tasks.Premailex.Gen.EntitiesTest do
    use ExUnit.Case

    import ExUnit.CaptureIO

    alias Mix.Tasks.Premailex.Gen.Entities

    @sample_json """
    {
      "&AElig": { "codepoints": [198], "characters": "\\u00C6" },
      "&AElig;": { "codepoints": [198], "characters": "\\u00C6" },
      "&AMP": { "codepoints": [38], "characters": "\\u0026" }
    }
    """

    setup context do
      test_name =
        context.test
        |> to_string()
        |> String.replace(~r/[^a-zA-Z0-9_-]+/, "-")

      output_path = Path.join([System.tmp_dir!(), to_string(context.module), test_name])
      status = Map.get(context, :status, 200)
      body = (status == 200 && @sample_json) || "Not Found"

      File.rm_rf!(output_path)
      File.mkdir_p!(output_path)

      TestServer.HTTP.handle("/entities.json",
        to: fn conn ->
          Plug.Conn.send_resp(conn, status, body)
        end
      )

      {:ok, url: TestServer.HTTP.url("/entities.json"), output: Path.join(output_path, "entities.txt")}
    end

    test "writes file", %{url: url, output: output} do
      log =
        capture_io(fn ->
          Entities.run(["--url", url, "--output", output])
        end)

      assert log =~ "Downloading #{url}..."
      assert log =~ "Wrote 3 entries to #{output}"

      assert File.read!(output) == """
             &AElig 198
             &AElig; 198
             &AMP 38
             """
    end

    @tag status: 404
    test "when url returns non-200 status", %{url: url, output: output} do
      assert_raise Mix.Error, ~r/Unexpected HTTP status 404/, fn ->
        assert capture_io(fn ->
                 Entities.run(["--url", url, "--output", output])
               end) =~ "Downloading #{url}..."
      end
    end

    test "when url not accessible", %{url: url, output: output} do
      TestServer.HTTP.stop()

      assert_raise Mix.Error, ~r/Request to #{url} failed/, fn ->
        assert capture_io(fn ->
                 Entities.run(["--url", url, "--output", output])
               end) =~ "Downloading #{url}..."
      end
    end
  end
end
