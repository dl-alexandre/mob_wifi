defmodule Mob.Wifi.WifiBridgeTest do
  use ExUnit.Case, async: true

  alias Mob.Wifi.CarrierRejectedError
  alias Mob.Wifi.WifiBridge

  defmodule NativeClient do
    @moduledoc false

    def send_frame(peer_id, frame, opts) do
      send(Keyword.fetch!(opts, :test_pid), {:wifi_sent, peer_id, frame})
      :ok
    end
  end

  describe "start_link/1" do
    test "requires event_target" do
      assert {:error, {:missing_required_option, :event_target}} = WifiBridge.start_link([])
    end

    test "rejects carriers not implemented by the initial bridge" do
      assert_raise CarrierRejectedError, fn ->
        WifiBridge.start_link(event_target: self(), carrier: :multipeer)
      end
    end
  end

  describe "Mob.Transport-compatible API" do
    test "delivers frames through an injected native client" do
      {:ok, bridge} = WifiBridge.start_link(event_target: self(), native_client: NativeClient)

      assert :ok = WifiBridge.send_frame(bridge, "peer-1", "hello", test_pid: self())
      assert_receive {:wifi_sent, "peer-1", "hello"}

      GenServer.stop(bridge)
    end

    test "returns an error when no native client is configured" do
      {:ok, bridge} = WifiBridge.start_link(event_target: self())

      assert {:error, :native_client_not_configured} =
               WifiBridge.send_frame(bridge, "peer-1", "hello")

      GenServer.stop(bridge)
    end

    test "enforces the configured frame budget" do
      {:ok, bridge} =
        WifiBridge.start_link(
          event_target: self(),
          native_client: NativeClient,
          max_frame_bytes: 2
        )

      assert {:error, {:frame_too_large, 5, 2}} =
               WifiBridge.send_frame(bridge, "peer-1", "hello", test_pid: self())

      GenServer.stop(bridge)
    end
  end

  describe "native event emission" do
    test "emits canonical transport events" do
      {:ok, bridge} = WifiBridge.start_link(event_target: self())

      assert :ok =
               WifiBridge.receive_native_event(bridge, {
                 :peer_up,
                 "peer-1",
                 %{"carrier" => "wifi_direct"}
               })

      assert :ok = WifiBridge.receive_native_event(bridge, {:frame, "peer-1", "hello"})
      assert :ok = WifiBridge.receive_native_event(bridge, {:peer_down, "peer-1"})

      assert_receive {:transport_up, "peer-1", %{"carrier" => "wifi_direct"}}
      assert_receive {:frame, "peer-1", "hello"}
      assert_receive {:transport_down, "peer-1"}

      GenServer.stop(bridge)
    end

    test "emits transport_error for unknown native events" do
      {:ok, bridge} = WifiBridge.start_link(event_target: self())

      assert {:error, {:unknown_native_event, %{bad: true}}} =
               WifiBridge.receive_native_event(bridge, %{bad: true})

      assert_receive {:transport_error, {:unknown_native_event, %{bad: true}}}

      GenServer.stop(bridge)
    end
  end
end
