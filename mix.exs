defmodule Lexicafe.MixProject do
  use Mix.Project

  def project do
    [
      app: :lexicafe,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {Lexicafe.Application, []},
      extra_applications: [:logger, :runtime_tools, :crypto]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.17"},
      {:phoenix_live_view, "~> 1.2"},
      {:phoenix_html, "~> 4.1"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:floki, ">= 0.36.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.create", "ecto.migrate", "assets.vendor"],
      "assets.vendor": [&vendor_assets/1],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp vendor_assets(_) do
    {out, status} = System.cmd("sh", ["scripts/vendor_assets.sh"], stderr_to_stdout: true)
    IO.write(out)
    if status != 0, do: Mix.raise("No se pudieron instalar los assets de Phoenix LiveView")
  end
end
