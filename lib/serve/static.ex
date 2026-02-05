defmodule Serve.Static do
  @moduledoc false
  # This is a wrapper around `Plug.Static` that allows us to dynamically set
  # the `:from` option. Additionally if the requested path is not found, it
  # will try to serve `index.htm*` file if it exists.

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: Plug.Static.init(opts)

  @impl true
  def call(conn, opts) do
    runtime_opts = Map.replace!(opts, :from, Serve.static_path())

    case Plug.Static.call(conn, runtime_opts) do
      %Plug.Conn{halted: true} = served_conn ->
        served_conn

      conn ->
        try_index(conn, runtime_opts)
    end
  end

  defp try_index(conn, runtime_opts) do
    Path.join([Serve.static_path()] ++ conn.path_info ++ ["index.htm*"])
    |> Path.wildcard()
    |> maybe_put_index(conn, runtime_opts)
  end

  defp maybe_put_index([], conn, _runtime_opts), do: conn

  defp maybe_put_index([index_path | _], conn, runtime_opts) do
    index_file = Path.basename(index_path)

    if String.ends_with?(conn.request_path, "/") do
      Plug.Static.call(put_in(conn.path_info, conn.path_info ++ [index_file]), runtime_opts)
    else
      redirect(conn, conn.request_path <> "/")
    end
  end

  defp redirect(conn, path) do
    html = Plug.HTML.html_escape(path)
    body = "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"

    conn
    |> put_resp_header("location", path)
    |> send_resp(conn.status || 302, body)
    |> halt()
  end
end
