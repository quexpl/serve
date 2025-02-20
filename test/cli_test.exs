defmodule Serve.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  @version "Serve v#{Application.spec(:serve, :vsn)}"
  @timeout 1500

  defp run(args) do
    capture_io(fn -> Serve.CLI.main(args) end)
  end

  test "help and version" do
    assert run(["--version"]) =~ @version
    assert run(["-v"]) =~ @version
    assert run(["--help"]) =~ "Usage: serve [OPTION] [DIR]"
    assert run(["-h"]) =~ "Starts HTTP Server in DIR (the current directory by default)."
  end

  test "unsupported options" do
    assert_raise RuntimeError, ~r/-x : Unknown option/, fn ->
      Serve.CLI.main(["-x"])
    end

    exception =
      assert_raise RuntimeError, fn ->
        Serve.CLI.main(["--port", "THREE"])
      end

    assert exception.message =~ "--port : Expected type integer, got \"THREE\""
    assert exception.message =~ "Usage: serve [OPTION] [DIR]"
  end

  @tag :tmp_dir
  test "accepts options", %{tmp_dir: tmp_dir} do
    cwd = File.cwd!()

    assert capture_log(fn ->
             task = Task.async(fn -> Serve.CLI.main(["-p", "4334"]) end)
             Task.yield(task, @timeout) || Task.shutdown(task)
             :timer.sleep(10)
           end) =~ ~r/Serving #{cwd} with Cowboy (.*) at http:\/\/(.*):4334/

    assert capture_log(fn ->
             task = Task.async(fn -> Serve.CLI.main(["-p", "31337", tmp_dir]) end)
             Task.yield(task, @timeout) || Task.shutdown(task)
             :timer.sleep(10)
           end) =~ ~r/Serving #{tmp_dir} with Cowboy (.*) at http:\/\/(.*):31337/
  end

  test "raise on invalid options" do
    assert_raise RuntimeError,
                 ~r/Invalid path. The path '\/non_existent\/dir\' does not exist./,
                 fn ->
                   Serve.CLI.main(["/non_existent/dir"])
                 end
  end

  test "env variables overrides options" do
    System.put_env("MIX_SERVE_PORT", "31337")

    assert capture_log(fn ->
             task = Task.async(fn -> Serve.CLI.main(["-p", "4441"]) end)
             Task.yield(task, @timeout) || Task.shutdown(task)
             :timer.sleep(10)
           end) =~ ~r/Serving (.*) with Cowboy (.*) at http:\/\/(.*):31337/

    System.delete_env("MIX_SERVE_PORT")
  end

  @tag :tmp_dir
  test "opens browser", %{tmp_dir: tmp_dir} do
    assert capture_log(fn ->
             task = Task.async(fn -> Serve.CLI.main(["-op", "4441", tmp_dir]) end)
             Task.yield(task, @timeout) || Task.shutdown(task)
             :timer.sleep(10)
           end) =~ ~r/System.cmd\((cmd|open|xdg-open), \[http:\/\/127.0.0.1:4441\]\)/
  end
end
