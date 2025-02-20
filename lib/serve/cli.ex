defmodule Serve.CLI do
  @moduledoc """
  Starts HTTP Server in DIR (the current directory by default).

  Usage: `serve [OPTION] [DIR]`

  Available options:
      -p, --port         specify the port to listen on (default: `4444`).
      -o, --open         open the browser automatically.
      -n, --no-index     disable directory listing.
      -v, --version      output version information and exit
      -h, --help         display this help and exit

  Examples:
      serve
      serve path/to/web
      serve -op 3000
  """
  def main(["--version"]), do: version()
  def main(["-v"]), do: version()

  def main(["--help"]), do: IO.puts(help())
  def main(["-h"]), do: IO.puts(help())

  def main(command_line_args) do
    valid_opts = [port: :integer, no_index: :boolean, open: :boolean]
    aliases = [p: :port, n: :no_index, o: :open]

    try do
      {opts, working_dir} =
        case OptionParser.parse_head!(command_line_args, strict: valid_opts, aliases: aliases) do
          {opts, []} ->
            {opts, File.cwd!()}

          {opts, [working_dir]} ->
            {opts, Path.expand(working_dir)}
        end

      {:ok, _supervisor} = runtime_config(opts, working_dir) |> start()
      Process.sleep(:infinity)
    rescue
      e in OptionParser.ParseError ->
        raise """
        Invalid arguments: #{e.message}

        #{help()}
        """

        exit({:shutdown, 1})
    end
  end

  defp start(opts) do
    Application.put_all_env(serve: opts)

    opts = [strategy: :one_for_one, name: Serve.ServerSupervisor]
    Supervisor.start_link([Serve.Server], opts)
  end

  defp version, do: IO.puts("Serve v#{Application.spec(:serve, :vsn)}")

  defp runtime_config(opts, working_dir) do
    verify_path(working_dir)

    [
      path: working_dir,
      port: runtime_option(opts, :port, :integer, 4444),
      no_index: runtime_option(opts, :no_index, :boolean, false),
      open: runtime_option(opts, :open, :boolean, false)
    ]
  end

  defp verify_path(working_dir) do
    unless File.exists?(working_dir) do
      raise """
      Invalid path. The path '#{working_dir}' does not exist.
      """
    end
  end

  defp runtime_option(opts, key, :boolean, default) do
    case System.get_env(env_var(key)) do
      "true" -> true
      "false" -> false
      _ -> Keyword.get(opts, key, default)
    end
  end

  defp runtime_option(opts, key, :integer, default) do
    case System.get_env(env_var(key)) do
      nil -> Keyword.get(opts, key, default)
      value -> parse_integer(value, default)
    end
  end

  defp env_var(key) do
    "MIX_SERVE_#{String.upcase(Atom.to_string(key))}"
  end

  defp parse_integer(maybe_int, default) do
    case Integer.parse(maybe_int) do
      {int, _} -> int
      _ -> default
    end
  end

  defp help() do
    """
    Usage: serve [OPTION] [DIR]
    Starts HTTP Server in DIR (the current directory by default).

    Available options:
      -p, --port         specify the port to listen on (default: `4444`).
      -o, --open         open the browser automatically.
      -n, --no-index     disable directory listing.
      -v, --version      output version information and exit
      -h, --help         display this help and exit

    Examples:
      serve
      serve path/to/web
      serve -op 3000
    """
  end
end
