defmodule ServeTest do
  use ExUnit.Case
  doctest Serve

  test "port/0 returns the default port" do
    assert Serve.port() == 4444

    Application.put_env(:serve, :port, 1234)
    assert Serve.port() == 1234
  end

  test "static_path/0 returns the default path" do
    assert Serve.static_path() == File.cwd!()

    Application.put_env(:serve, :path, "/tmp")
    assert Serve.static_path() == "/tmp"
  end

  test "backend/0 returns the default backend" do
    assert Serve.backend() == :cowboy
  end

  test "index?/0 returns the default index value" do
    assert Serve.index?() == true

    Application.put_env(:serve, :no_index, true)
    assert Serve.index?() == false
  end

  test "open?/0 returns the default open value" do
    assert Serve.open?() == false

    Application.put_env(:serve, :open, true)
    assert Serve.open?() == true
  end
end
