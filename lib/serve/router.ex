defmodule Serve.Router do
  @moduledoc false
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger)

  plug(Serve.Static,
    at: "/",
    from: Serve.static_path(),
    gzip: false
  )

  plug(:match)
  plug(:dispatch)

  get "/__info__" do
    output = template("Mix Serve", "Serve v#{Application.spec(:serve, :vsn)}")
    send_resp(conn, 200, output)
  end

  match(_, do: handle_not_found(conn))

  defp handle_not_found(conn) do
    case Serve.index?() do
      true ->
        index(conn)

      false ->
        not_found(conn)
    end
  end

  defp not_found(conn) do
    file = Path.join(Serve.static_path(), conn.request_path)

    output = template("Not found", "File #{file} cannot be found")

    send_resp(conn, 404, output)
    |> halt()
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    output = template("Error", "Something went wrong", Exception.format(kind, reason, stack))

    send_resp(conn, conn.status, output)
    |> halt()
  end

  defp index(conn) do
    Path.join(Serve.static_path(), conn.request_path)
    |> File.exists?()
    |> maybe_serve_index(conn)
  end

  defp maybe_serve_index(false, conn), do: not_found(conn)

  defp maybe_serve_index(true, conn) do
    files =
      index_files(conn)
      |> parent_path_info(conn)

    output = """
    <ul>
      #{Enum.join(files)}
    </ul>
    """

    output = template("Index of #{conn.request_path}", "", {:raw, output})
    send_resp(conn, 200, output)
  end

  defp index_files(conn) do
    (Path.join([Serve.static_path()] ++ conn.path_info) <> "/*")
    |> Path.wildcard()
    |> Enum.map(&if File.dir?(&1), do: Path.basename(&1) <> "/", else: Path.basename(&1))
    |> Enum.sort()
    |> Enum.map(&index_link(conn.path_info ++ [&1]))
  end

  defp parent_path_info(files, %Plug.Conn{path_info: []}), do: files

  defp parent_path_info(files, %Plug.Conn{path_info: path_info}) do
    parent_path =
      Enum.reverse(path_info)
      |> tl()
      |> Enum.reverse()

    [index_link(parent_path, "..")] ++ files
  end

  defp index_link(path) do
    name = List.last(path)
    index_link(path, name)
  end

  defp index_link(path, name) do
    """
    <li><a href="/#{Enum.join(path, "/")}">#{name}</a></li>
    """
  end

  defp template(title, description, body \\ "") do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <title>#{title}</title>
        <meta name="viewport" content="width=device-width">
        <style>
        :root {
            --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Oxygen", "Ubuntu", "Cantarell", "Fira Sans", "Droid Sans", "Helvetica Neue", sans-serif;

            /* Light Theme */
            --background-color: #fff;
            --text-color: #000;
            --heading-bg: #f9f9fa;
            --error-color: #FF6467;
            --subtext-color: #a0b0c0;
            --closure-bg: #f9f9fa;
            --closure-text-color: #a0b0c0;
            --link-color: #9F90EA;;
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --background-color: #1B1B1B;
                --text-color: #fff;
                --heading-bg: #343434;
                --closure-bg: #343434;
            }
        }

        html, body, td, input {
            font-family: var(--font-family);
        }

        * {
            box-sizing: border-box;
        }

        html {
            font-size: 15px;
            line-height: 1.6;
            background: var(--background-color);
            color: var(--text-color);
        }

        a {
          color: var(--link-color);
          text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        .heading-block {
            background: var(--heading-bg);
        }

        .heading-block,
        .output-block {
            padding: 48px;
        }

        .code-block {
            margin: 0;
            font-size: .85em;
            line-height: 1.6;
            white-space: pre-wrap;
        }

        .exception-info > .error,
        .exception-info > .subtext {
            margin: 0;
            padding: 0;
        }

        .exception-info > .error {
            font-size: 1em;
            font-weight: 700;
            color: var(--error-color);
        }

        .exception-info > .subtext {
            font-size: 1em;
            font-weight: 400;
            color: var(--subtext-color);
        }

        .closure-block {
            padding: 24px;
            background: var(--closure-bg);
            color: var(--closure-text-color);
            font-size: .85em;
            line-height: 1.6;
        }

        </style>
    </head>
    <body>
        <div class="heading-block">
            <aside class="exception-logo"></aside>
            <header class="exception-info">
                <h5 class="error">#{title}</h5>
                <h5 class="subtext">#{description}</h5>
            </header>
        </div>
        <div class="output-block">
            #{format_output(body)}
        </div>

        <div class="closure-block">
          <p>Generated by <a href="https://hexdocs.pm/serve">Serve</a> v#{Application.spec(:serve, :vsn)}</p>
        </div>
    </body>
    </html>
    """
  end

  defp format_output({:raw, output}), do: output

  defp format_output(output) do
    output =
      output
      |> IO.iodata_to_binary()
      |> String.trim()
      |> Plug.HTML.html_escape()

    """
    <pre class="code code-block">#{output}</pre>
    """
  end
end
