defmodule Mob.WifiTest do
  use ExUnit.Case, async: true

  alias Mob.Wifi.CarrierRejectedError

  describe "public API" do
    test "uses wifi_direct as the initial primary carrier" do
      assert Mob.Wifi.carrier() == :wifi_direct
      assert Mob.Wifi.bridge_module() == Mob.Wifi.WifiBridge
      assert Mob.Wifi.default_bridge() == Mob.Wifi.WifiBridge
    end
  end

  describe "validate_config/1" do
    test "accepts empty and recognized carrier configs" do
      assert :ok = Mob.Wifi.validate_config([])
      assert :ok = Mob.Wifi.validate_config(%{})
      assert :ok = Mob.Wifi.validate_config(carrier: :wifi_direct)
      assert :ok = Mob.Wifi.validate_config(carrier: :multipeer)
      assert :ok = Mob.Wifi.validate_config(carrier: :bonjour_tcp)
    end

    test "rejects unsupported carriers" do
      assert_raise CarrierRejectedError, fn ->
        Mob.Wifi.validate_config(carrier: :wifi_aware)
      end
    end

    test "validates known typed options" do
      assert :ok =
               Mob.Wifi.validate_config(
                 platform: :android,
                 evidence_mode: :diagnostic,
                 max_frame_bytes: 4096,
                 discovery: :native,
                 log_level: :info,
                 native?: false
               )

      assert {:error, {:invalid_config, :platform, :web}} =
               Mob.Wifi.validate_config(platform: :web)

      assert {:error, {:invalid_config, :evidence_mode, :lab}} =
               Mob.Wifi.validate_config(evidence_mode: :lab)

      assert {:error, {:invalid_config, :max_frame_bytes, 0}} =
               Mob.Wifi.validate_config(max_frame_bytes: 0)

      assert {:error, {:invalid_config, :discovery, :bluetooth}} =
               Mob.Wifi.validate_config(discovery: :bluetooth)

      assert {:error, {:invalid_config, :log_level, "info"}} =
               Mob.Wifi.validate_config(log_level: "info")

      assert {:error, {:invalid_config, :native?, "false"}} =
               Mob.Wifi.validate_config(native?: "false")
    end
  end
end
