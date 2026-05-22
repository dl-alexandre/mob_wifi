defmodule Mob.Wifi.HardwareCheckTest do
  use ExUnit.Case, async: true

  alias Mob.Wifi.HardwareCheck

  test "parses adb devices output" do
    output = """
    List of devices attached
    abc123 device usb:1-1 product:test model:Pixel_8 device:pixel transport_id:1
    offline123 offline
    """

    assert [
             %{serial: "abc123", model: "Pixel_8", features: features}
           ] = HardwareCheck.parse_adb_devices(output)

    assert MapSet.size(features) == 0
  end

  test "parses Android WiFi features" do
    output = """
    feature:android.hardware.wifi
    feature:android.hardware.wifi.direct
    feature:android.hardware.wifi.aware
    """

    features = HardwareCheck.parse_android_features(output)

    assert MapSet.member?(features, "android.hardware.wifi.direct")
    assert MapSet.member?(features, "android.hardware.wifi.aware")
  end

  test "parses online iOS devices from idevice_id and xctrace" do
    idevice_output = """
    00008030-000209510ED0C02E
    2aa4be71ef18d7cb65191287cbc729b91e3f0635
    """

    xctrace_output = """
    == Devices ==
    DairyBookPro (5A9B7641-9201-5D6E-B0D2-EBDD48C04FD3)
    Coding iPad (26.5) (00008030-000209510ED0C02E)
    TestPad (17.7.11) (2aa4be71ef18d7cb65191287cbc729b91e3f0635)
    == Devices Offline ==
    OfflinePhone (26.4.2) (00008110-0006619A2132801E)
    """

    assert [
             %{name: "Coding iPad", version: "26.5", udid: "00008030-000209510ED0C02E"},
             %{
               name: "TestPad",
               version: "17.7.11",
               udid: "2aa4be71ef18d7cb65191287cbc729b91e3f0635"
             }
           ] = HardwareCheck.parse_ios_devices(idevice_output, xctrace_output)
  end

  test "builds lane readiness from command output" do
    runner = fn
      "adb", ["devices", "-l"], _opts ->
        {"""
         List of devices attached
         a1 device model:One
         a2 device model:Two
         """, 0}

      "adb", ["-s", _serial, "shell", "pm", "list", "features"], _opts ->
        {"""
         feature:android.hardware.wifi
         feature:android.hardware.wifi.direct
         """, 0}

      "idevice_id", ["-l"], _opts ->
        {"ios1\nios2\n", 0}

      "xcrun", ["xctrace", "list", "devices"], _opts ->
        {"""
         == Devices ==
         iPad A (26.5) (ios1)
         iPad B (26.5) (ios2)
         """, 0}
    end

    report =
      HardwareCheck.run(
        %{},
        fn command, args, opts ->
          runner.(Path.basename(command), args, opts)
        end,
        %{adb: "adb", xcrun: "xcrun", idevice_id: "idevice_id"}
      )

    assert %{status: :available} = Enum.find(report.lanes, &(&1.id == :android_wifi_direct))
    assert %{status: :blocked} = Enum.find(report.lanes, &(&1.id == :android_wifi_aware))
    assert %{status: :available} = Enum.find(report.lanes, &(&1.id == :ios_multipeer))

    assert %{status: :available} =
             Enum.find(report.lanes, &(&1.id == :bonjour_tcp_cross_platform))
  end
end
