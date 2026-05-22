defmodule Mob.Wifi.HardwareCheck do
  @moduledoc """
  Detects attached hardware suitable for `mob_wifi` validation lanes.

  This module intentionally performs readiness checks only. It does not start
  WiFi Direct, Multipeer, or Bonjour sessions.
  """

  @type command_runner ::
          (String.t(), [String.t()], keyword() -> {String.t(), non_neg_integer()})

  @type android_device :: %{
          serial: String.t(),
          model: String.t() | nil,
          features: MapSet.t(String.t())
        }

  @type ios_device :: %{
          udid: String.t(),
          name: String.t() | nil,
          version: String.t() | nil
        }

  @type lane :: %{
          id: atom(),
          status: :available | :blocked,
          reason: String.t()
        }

  @type report :: %{
          tools: map(),
          android_devices: [android_device()],
          ios_devices: [ios_device()],
          env: map(),
          lanes: [lane()]
        }

  @android_direct "android.hardware.wifi.direct"
  @android_aware "android.hardware.wifi.aware"
  @command_timeout 10_000

  @doc "Builds a hardware readiness report from attached devices and host tools."
  @spec run(map(), command_runner(), map()) :: report()
  def run(env \\ System.get_env(), command_runner \\ &System.cmd/3, tool_paths \\ tools()) do
    android_devices = android_devices(tool_paths, command_runner)
    ios_devices = ios_devices(tool_paths, command_runner)

    %{
      tools: tool_paths,
      android_devices: android_devices,
      ios_devices: ios_devices,
      env: env_summary(env),
      lanes: lanes(android_devices, ios_devices)
    }
  end

  @doc "Returns true when every lane in the report is available."
  @spec ready?(report()) :: boolean()
  def ready?(report), do: Enum.all?(report.lanes, &(&1.status == :available))

  @doc "Parses `adb devices -l` output."
  @spec parse_adb_devices(String.t()) :: [android_device()]
  def parse_adb_devices(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reject(&String.starts_with?(&1, "List of devices attached"))
    |> Enum.flat_map(&parse_adb_line/1)
  end

  @doc "Parses `pm list features` output into a feature set."
  @spec parse_android_features(String.t()) :: MapSet.t(String.t())
  def parse_android_features(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.flat_map(fn
      "feature:" <> feature -> [String.trim(feature)]
      _other -> []
    end)
    |> MapSet.new()
  end

  @doc "Parses online iOS devices from `idevice_id -l` and `xcrun xctrace list devices` output."
  @spec parse_ios_devices(String.t(), String.t()) :: [ios_device()]
  def parse_ios_devices(idevice_output, xctrace_output) do
    online_udids =
      idevice_output
      |> String.split("\n", trim: true)
      |> MapSet.new()

    xctrace_output
    |> String.split("\n", trim: true)
    |> Enum.flat_map(&parse_xctrace_line/1)
    |> Enum.filter(&MapSet.member?(online_udids, &1.udid))
    |> merge_missing_ios_devices(online_udids)
  end

  @doc "Formats a report for CLI output."
  @spec format(report()) :: String.t()
  def format(report) do
    [
      "mob_wifi hardware readiness",
      "",
      "Tools:",
      format_tool("adb", report.tools.adb),
      format_tool("xcrun", report.tools.xcrun),
      format_tool("idevice_id", report.tools.idevice_id),
      "",
      "Android devices:",
      format_android_devices(report.android_devices),
      "",
      "iOS devices:",
      format_ios_devices(report.ios_devices),
      "",
      "Environment:",
      "  MOB_WIFI_ANDROID_A=#{report.env.android_a || "<unset>"}",
      "  MOB_WIFI_ANDROID_B=#{report.env.android_b || "<unset>"}",
      "  MOB_WIFI_IOS_A=#{report.env.ios_a || "<unset>"}",
      "  MOB_WIFI_IOS_B=#{report.env.ios_b || "<unset>"}",
      "",
      "Validation lanes:",
      Enum.map(report.lanes, &format_lane/1)
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp tools do
    %{
      adb: System.find_executable("adb"),
      xcrun: System.find_executable("xcrun"),
      idevice_id: System.find_executable("idevice_id")
    }
  end

  defp android_devices(%{adb: nil}, _command_runner), do: []

  defp android_devices(%{adb: adb}, command_runner) do
    {devices_output, _status} = command(command_runner, adb, ["devices", "-l"])

    devices = parse_adb_devices(devices_output)

    Enum.map(devices, fn device ->
      {features_output, _status} =
        command(command_runner, adb, ["-s", device.serial, "shell", "pm", "list", "features"])

      %{device | features: parse_android_features(features_output)}
    end)
  end

  defp ios_devices(%{xcrun: nil}, _command_runner), do: []
  defp ios_devices(%{idevice_id: nil}, _command_runner), do: []

  defp ios_devices(%{xcrun: xcrun, idevice_id: idevice_id}, command_runner) do
    {idevice_output, _status} = command(command_runner, idevice_id, ["-l"])
    {xctrace_output, _status} = command(command_runner, xcrun, ["xctrace", "list", "devices"])
    parse_ios_devices(idevice_output, xctrace_output)
  end

  defp command(command_runner, executable, args) do
    task =
      Task.async(fn ->
        command_runner.(executable, args, stderr_to_stdout: true)
      end)

    case Task.yield(task, @command_timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> {"command timed out after #{@command_timeout}ms\n", 124}
    end
  rescue
    error -> {"#{Exception.message(error)}\n", 1}
  catch
    :exit, reason -> {"#{inspect(reason)}\n", 1}
  end

  defp env_summary(env) do
    %{
      android_a: Map.get(env, "MOB_WIFI_ANDROID_A"),
      android_b: Map.get(env, "MOB_WIFI_ANDROID_B"),
      ios_a: Map.get(env, "MOB_WIFI_IOS_A"),
      ios_b: Map.get(env, "MOB_WIFI_IOS_B")
    }
  end

  defp lanes(android_devices, ios_devices) do
    [
      android_wifi_direct_lane(android_devices),
      android_wifi_aware_lane(android_devices),
      ios_multipeer_lane(ios_devices),
      bonjour_tcp_lane(android_devices, ios_devices)
    ]
  end

  defp android_wifi_direct_lane(devices) do
    count = Enum.count(devices, &feature?(&1, @android_direct))

    lane(:android_wifi_direct, count >= 2, "#{count} Android device(s) report WiFi Direct")
  end

  defp android_wifi_aware_lane(devices) do
    count = Enum.count(devices, &feature?(&1, @android_aware))

    lane(:android_wifi_aware, count >= 2, "#{count} Android device(s) report WiFi Aware")
  end

  defp ios_multipeer_lane(devices) do
    count = length(devices)

    lane(:ios_multipeer, count >= 2, "#{count} online iOS device(s) detected")
  end

  defp bonjour_tcp_lane(android_devices, ios_devices) do
    lane(
      :bonjour_tcp_cross_platform,
      android_devices != [] and ios_devices != [],
      "#{length(android_devices)} Android device(s), #{length(ios_devices)} iOS device(s) detected"
    )
  end

  defp lane(id, true, reason), do: %{id: id, status: :available, reason: reason}
  defp lane(id, false, reason), do: %{id: id, status: :blocked, reason: reason}

  defp feature?(device, feature), do: MapSet.member?(device.features, feature)

  defp parse_adb_line(line) do
    fields = String.split(line)

    case fields do
      [serial, "device" | rest] ->
        [%{serial: serial, model: model(rest), features: MapSet.new()}]

      _other ->
        []
    end
  end

  defp model(fields) do
    Enum.find_value(fields, fn field ->
      case String.split(field, "model:", parts: 2) do
        ["", value] -> value
        _other -> nil
      end
    end)
  end

  defp parse_xctrace_line(line) do
    case Regex.run(~r/^(.+) \(([^)]+)\) \(([^)]+)\)$/, line) do
      [_line, name, version, udid] -> [%{name: name, version: version, udid: udid}]
      _other -> []
    end
  end

  defp merge_missing_ios_devices(devices, online_udids) do
    known = MapSet.new(devices, & &1.udid)

    missing =
      online_udids
      |> Enum.reject(&MapSet.member?(known, &1))
      |> Enum.map(&%{udid: &1, name: nil, version: nil})

    devices ++ missing
  end

  defp format_tool(name, nil), do: "  #{name}: missing"
  defp format_tool(name, path), do: "  #{name}: #{path}"

  defp format_android_devices([]), do: "  <none>"

  defp format_android_devices(devices) do
    Enum.map(devices, fn device ->
      features =
        [
          if(feature?(device, @android_direct), do: "wifi_direct"),
          if(feature?(device, @android_aware), do: "wifi_aware")
        ]
        |> Enum.reject(&is_nil/1)
        |> case do
          [] -> "no mob_wifi carrier features"
          values -> Enum.join(values, ", ")
        end

      "  #{device.serial} #{device.model || "<unknown model>"} (#{features})"
    end)
  end

  defp format_ios_devices([]), do: "  <none>"

  defp format_ios_devices(devices) do
    Enum.map(devices, fn device ->
      name = device.name || "<unknown name>"
      version = device.version || "<unknown version>"
      "  #{device.udid} #{name} (#{version})"
    end)
  end

  defp format_lane(%{id: id, status: status, reason: reason}) do
    "  #{id}: #{status} - #{reason}"
  end
end
