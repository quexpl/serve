defmodule Serve.Server do
  @moduledoc false
  use Supervisor

  require Logger

  def start_link(init_arg) do
    with {:ok, pid} <- Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__) do
      url = "http://127.0.0.1:#{Serve.port()}"
      backend = Atom.to_string(Serve.backend()) |> String.capitalize()
      backend_version = Application.spec(Serve.backend(), :vsn)

      Logger.info("Serving #{Serve.static_path()} with #{backend} #{backend_version} at #{url}")

      browser_open(url)
      {:ok, pid}
    end
  end

  def init(_init_arg) do
    Supervisor.init(
      [
        {Plug.Cowboy,
         ip: {127, 0, 0, 1}, plug: Serve.Router, scheme: :http, options: [port: Serve.port()]}
      ],
      strategy: :one_for_one
    )
  end

  defp browser_open(url) do
    if Serve.open?() do
      {cmd, args} =
        case :os.type() do
          {:win32, _} -> {"cmd", ["/c", "start", url]}
          {:unix, :darwin} -> {"open", [url]}
          {:unix, _} -> {"xdg-open", [url]}
        end

      if test?(), do: cmd(cmd, args), else: System.cmd(cmd, args)
    end
  end

  defp test?, do: Code.loaded?(Mix) && Mix.env() == :test

  defp cmd(cmd, args) do
    Logger.info("System.cmd(#{cmd}, [#{Enum.join(args, ",")}])")
  end
end
