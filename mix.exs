defmodule Mob.Wifi.MixProject do
  use Mix.Project

  @github_url "https://github.com/dl-alexandre/mob_wifi"
  @version "0.2.0"
  @description "Production WiFi transport plugin for mob with validated Android WiFi Direct, iOS Multipeer, and cross-platform Bonjour/TCP carrier policy."

  def project do
    [
      app: :mob_wifi,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      source_url: @github_url,
      homepage_url: @github_url,
      dialyzer: dialyzer(),
      docs: [
        main: "readme",
        extras: [
          "README.md",
          "docs/CARRIER_DECISION.md",
          "docs/CARRIER_IMPLEMENTATION.md",
          "docs/MIGRATION.md",
          "docs/PERFORMANCE.md",
          "docs/PLUGIN_LOADING.md",
          "docs/SECURITY.md",
          "docs/TESTING.md",
          "docs/TELEMETRY.md",
          "CHANGELOG.md",
          "CONTRIBUTING.md",
          "LICENSE"
        ]
      ]
    ]
  end

  def application do
    [
      mod: {MobWifi.Application, []},
      extra_applications: [:logger, :telemetry]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:nimble_options, "~> 1.1"},
      {:stream_data, "~> 1.2", only: :test},
      {:telemetry, "~> 1.3"},
      {:ex_doc, "~> 0.40.2", only: :dev, runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_local_path: "_build/plts",
      plt_core_path: "_build/plts",
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Changelog" => "#{@github_url}/blob/main/CHANGELOG.md",
        "mob" => "https://github.com/GenericJam/mob",
        "mob_dev" => "https://github.com/GenericJam/mob_dev"
      },
      files: ~w(
        lib
        priv/mob_plugin.exs
        docs
        .github/dependabot.yml
        .github/workflows/ci.yml
        .formatter.exs
        .dialyzer_ignore.exs
        mix.exs
        README.md
        CHANGELOG.md
        CONTRIBUTING.md
        LICENSE
      )
    ]
  end
end
