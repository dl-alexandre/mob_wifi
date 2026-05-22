defmodule MobWifi.Application do
  @moduledoc """
  OTP application for the `mob_wifi` plugin.
  """

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    config = Application.get_env(:mob_wifi, :config, [])
    Logger.info("mob_wifi starting with config: #{inspect(config)}")

    case Mob.Wifi.validate_config(config) do
      :ok -> :ok
      err -> raise "mob_wifi validate_config failed: #{inspect(err)}"
    end

    Supervisor.start_link([], strategy: :one_for_one, name: MobWifi.Supervisor)
  end

  @impl true
  def stop(_state) do
    Logger.info("mob_wifi stopping")
    :ok
  end
end
