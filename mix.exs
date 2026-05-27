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
      # Coverage is reported in the umbrella summary but not gated here; this
      # plugin is published independently (threshold 0 => summary only, never fails).
      test_coverage: [summary: [threshold: 0]],
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
          "docs/HARDWARE_VALIDATION.md",
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
    transport_dep() ++
      [
        {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
        {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
        {:nimble_options, "~> 1.1"},
        {:stream_data, "~> 1.2", only: :test},
        {:telemetry, "~> 1.3"},
        {:ex_doc, "~> 0.40.2", only: :dev, runtime: false}
      ]
  end

  # Resolve the shared Mob.Transport contract from the sibling app when developed
  # inside the umbrella; omit it entirely from the published package (the
  # behaviour is applied optionally via Code.ensure_loaded?/1).
  defp transport_dep do
    if File.exists?(Path.expand("../mob_transport/mix.exs", __DIR__)),
      do: [{:mob_transport, in_umbrella: true}],
      else: []
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix],
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
        .github/workflows/hardware.yml
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
