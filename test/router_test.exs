defmodule Serve.StaticTest do
  use ExUnit.Case
  use Plug.Test

  alias Serve.Router

  setup do
    Application.put_env(:serve, :path, Path.join(File.cwd!(), "test/fixtures/webroot"))
    on_exit(fn -> Application.delete_env(:serve, :path) end)
  end

  test "serves static files" do
    conn =
      conn(:get, "/index.html")
      |> Router.call(%{})

    assert conn.status == 200
    assert conn.resp_body =~ "Hello World!"
  end

  test "serves index.html when is available" do
    conn =
      conn(:get, "/")
      |> Router.call(%{})

    assert conn.status == 200
    assert conn.resp_body =~ "Hello World!"
  end

  test "force the trailing slash for directories with index.html" do
    conn =
      conn(:get, "/contact")
      |> Router.call(%{})

    assert conn.status == 302
    assert ["/contact/"] = Plug.Conn.get_resp_header(conn, "location")
  end

  test "serves index.html from nested directories" do
    conn =
      conn(:get, "/nested/dir/")
      |> Router.call(%{})

    assert conn.status == 200
    assert conn.resp_body =~ "Nested Index"
  end

  test "redirects to trailing slash for nested directories with index" do
    conn =
      conn(:get, "/nested/dir")
      |> Router.call(%{})

    assert conn.status == 302
    assert ["/nested/dir/"] = Plug.Conn.get_resp_header(conn, "location")
  end

  test "returns 404 for missing files" do
    conn =
      conn(:get, "/missing.html")
      |> Router.call(%{})

    assert conn.status == 404
    assert conn.resp_body =~ ~r/File (.*)webroot\/missing\.html cannot be found/
  end

  test "returns directory listing when file is not found" do
    Application.put_env(:serve, :no_index, false)

    conn =
      conn(:get, "/noindex")
      |> Router.call(%{})

    assert conn.status == 200
    assert conn.resp_body =~ "Index of /noindex"
    assert conn.resp_body =~ ~r/<a href="\/noindex\/file\.txt">file\.txt<\/a>/
    assert conn.resp_body =~ ~r/<a href="\/">..<\/a>/

    Application.put_env(:serve, :path, Path.join(File.cwd!(), "test/fixtures/webroot/noindex"))

    conn =
      conn(:get, "/")
      |> Router.call(%{})

    assert conn.status == 200
    assert conn.resp_body =~ "Index of /"
    assert conn.resp_body =~ ~r/<a href="\/file\.txt">file\.txt<\/a>/
    refute conn.resp_body =~ ~r/<a href="\/">..<\/a>/

    Application.delete_env(:serve, :no_index)
    Application.delete_env(:serve, :path)
  end

  test "returns 404 when no index.html is available and directory index is disabled" do
    Application.put_env(:serve, :no_index, true)

    conn =
      conn(:get, "/noindex")
      |> Router.call(%{})

    Application.delete_env(:serve, :no_index)

    assert conn.status == 404
    assert conn.resp_body =~ ~r/File (.*)webroot\/noindex cannot be found/
  end

  test "/__info__ returns the version" do
    conn =
      conn(:get, "/__info__")
      |> Router.call(%{})

    assert conn.status == 200
    assert conn.resp_body =~ "Serve v#{Application.spec(:serve, :vsn)}"
  end
end
