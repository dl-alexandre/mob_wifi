defmodule Mob.Wifi.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mob.Wifi.WifiBridge

  defmodule NativeClient do
    @moduledoc false

    def send_frame(_peer_id, _frame, _opts), do: :ok
  end

  property "positive max_frame_bytes values are valid" do
    check all(bytes <- positive_integer()) do
      assert :ok = Mob.Wifi.validate_config(max_frame_bytes: bytes)
    end
  end

  property "non-positive max_frame_bytes values are rejected" do
    check all(bytes <- integer(-1_000..0)) do
      assert {:error, {:invalid_config, :max_frame_bytes, ^bytes}} =
               Mob.Wifi.validate_config(max_frame_bytes: bytes)
    end
  end

  property "frames at or below the configured budget are accepted" do
    check all(
            max_frame_bytes <- integer(1..128),
            frame <- binary(max_length: max_frame_bytes)
          ) do
      {:ok, bridge} =
        WifiBridge.start_link(
          event_target: self(),
          native_client: NativeClient,
          max_frame_bytes: max_frame_bytes
        )

      assert :ok = WifiBridge.send_frame(bridge, "peer-1", frame)
      GenServer.stop(bridge)
    end
  end

  property "frames above the configured budget are rejected" do
    check all(
            max_frame_bytes <- integer(1..128),
            extra_bytes <- integer(1..32)
          ) do
      frame = :binary.copy(<<0>>, max_frame_bytes + extra_bytes)
      frame_size = byte_size(frame)

      {:ok, bridge} =
        WifiBridge.start_link(
          event_target: self(),
          native_client: NativeClient,
          max_frame_bytes: max_frame_bytes
        )

      assert {:error, {:frame_too_large, ^frame_size, ^max_frame_bytes}} =
               WifiBridge.send_frame(bridge, "peer-1", frame)

      GenServer.stop(bridge)
    end
  end
end
