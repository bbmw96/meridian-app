defmodule MeridianRealtime.MixProject do
  use Mix.Project

  def project do
    [
      app: :meridian_realtime,
      version: "2.0.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MeridianRealtime.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_live_view, "~> 0.20.17"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:websock_adapter, "~> 0.5.7"},
      {:httpoison, "~> 2.2"},
      {:ex_rated, "~> 2.1"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
