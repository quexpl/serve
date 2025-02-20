defmodule Serve do
  @moduledoc false

  @doc false
  def port do
    Application.get_env(:serve, :port, 4444)
  end

  @doc false
  def static_path do
    Application.get_env(:serve, :path, File.cwd!())
  end

  @doc false
  def backend, do: :cowboy

  @doc false
  def index? do
    not Application.get_env(:serve, :no_index, false)
  end

  @doc false
  def open? do
    Application.get_env(:serve, :open, false)
  end
end
