defmodule Serve.MixProject do
  use Mix.Project

  def project do
    [
      app: :serve,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      escript: escript(),
      description: "Serve escript to quickly start an HTTP server",
      package: [
        links: %{
          "GitHub" => "https://github.com/quexpl/serve"
        },
        maintainers: ["Piotr Baj"],
        licenses: ["MIT"]
      ],
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      test_options: [docs: true],
      test_coverage: [summary: [threshold: 85]],
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.7"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp aliases do
    [
      install: ["deps.get", "escript.build", "escript.install"],
    ]
  end

  defp escript do
    [
      main_module: Serve.CLI
    ]
  end
end
