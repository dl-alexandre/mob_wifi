defmodule Mix.Tasks.MobWifi.Hardware.Check do
  @moduledoc """
  Checks attached hardware readiness for `mob_wifi` validation lanes.

      mix mob_wifi.hardware.check
      mix mob_wifi.hardware.check --strict

  `--strict` exits non-zero unless every known validation lane is available.
  """

  use Mix.Task

  alias Mob.Wifi.HardwareCheck

  @shortdoc "Checks attached mob_wifi hardware readiness"

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} = OptionParser.parse(args, strict: [strict: :boolean])
    report = HardwareCheck.run()

    Mix.shell().info(HardwareCheck.format(report))

    if opts[:strict] && !HardwareCheck.ready?(report) do
      Mix.raise("not all mob_wifi hardware validation lanes are available")
    end
  end
end
