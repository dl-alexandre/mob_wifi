defmodule Mob.Wifi.HardwareReadinessTest do
  use ExUnit.Case, async: false

  alias Mob.Wifi.HardwareCheck

  @moduletag :hardware

  setup_all do
    report = HardwareCheck.run()

    IO.puts("
" <> HardwareCheck.format(report))

    {:ok, report: report}
  end

  test "attached devices can exercise Android WiFi Direct", %{report: report} do
    assert_available(report, :android_wifi_direct)
  end

  test "attached devices can exercise iOS Multipeer", %{report: report} do
    assert_available(report, :ios_multipeer)
  end

  test "attached devices can exercise Bonjour/TCP cross-platform validation", %{report: report} do
    assert_available(report, :bonjour_tcp_cross_platform)
  end

  test "WiFi Aware readiness is reported without failing the lab suite", %{report: report} do
    lane = lane!(report, :android_wifi_aware)

    assert lane.status in [:available, :blocked]
    assert lane.reason =~ "WiFi Aware"
  end

  test "configured Android device IDs are attached when provided", %{report: report} do
    configured = [report.env.android_a, report.env.android_b] |> Enum.reject(&is_nil/1)
    attached = MapSet.new(report.android_devices, & &1.serial)

    assert Enum.all?(configured, &MapSet.member?(attached, &1))
  end

  test "configured iOS device IDs are attached when provided", %{report: report} do
    configured = [report.env.ios_a, report.env.ios_b] |> Enum.reject(&is_nil/1)
    attached = MapSet.new(report.ios_devices, & &1.udid)

    assert Enum.all?(configured, &MapSet.member?(attached, &1))
  end

  defp assert_available(report, lane_id) do
    assert %{status: :available} = lane!(report, lane_id)
  end

  defp lane!(report, lane_id) do
    Enum.find(report.lanes, &(&1.id == lane_id)) ||
      flunk("missing hardware validation lane #{inspect(lane_id)}")
  end
end
