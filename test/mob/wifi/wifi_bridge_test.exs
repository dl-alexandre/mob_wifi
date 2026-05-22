defmodule Mob.Wifi.WifiBridgeTest do
  use ExUnit.Case, async: true

  alias Mob.Wifi.CarrierRejectedError
  alias Mob.Wifi.WifiBridge

  setup do
    ref = make_ref()

    events = [
      [:mob_wifi, :bridge, :started],
      [:mob_wifi, :bridge, :start],
      [:mob_wifi, :frame, :sent],
      [:mob_wifi, :frame, :send_error],
      [:mob_wifi, :frame, :received],
      [:mob_wifi, :peer, :discovered],
      [:mob_wifi, :peer, :up],
      [:mob_wifi, :peer, :down],
      [:mob_wifi, :bridge, :error]
    ]

    for event <- events do
      :telemetry.attach({__MODULE__, ref, event}, event, &__MODULE__.handle_telemetry/4, {
        self(),
        ref
      })
    end

    on_exit(fn ->
      for event <- events do
        :telemetry.detach({__MODULE__, ref, event})
      end
    end)

    {:ok, telemetry_ref: ref}
  end

  def handle_telemetry(event, measurements, metadata, {test_pid, ref}) do
    send(test_pid, {ref, event, measurements, metadata})
  end

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
    test "delivers frames through an injected native client", %{telemetry_ref: telemetry_ref} do
      {:ok, bridge} = WifiBridge.start_link(event_target: self(), native_client: NativeClient)

      assert :ok = WifiBridge.send_frame(bridge, "peer-1", "hello", test_pid: self())
      assert_receive {:wifi_sent, "peer-1", "hello"}

      assert_receive {^telemetry_ref, [:mob_wifi, :frame, :sent], %{bytes: 5},
                      %{carrier: :wifi_direct, peer_id: "peer-1"}}

      GenServer.stop(bridge)
    end

    test "returns an error when no native client is configured", %{telemetry_ref: telemetry_ref} do
      {:ok, bridge} = WifiBridge.start_link(event_target: self())

      assert {:error, :native_client_not_configured} =
               WifiBridge.send_frame(bridge, "peer-1", "hello")

      assert_receive {^telemetry_ref, [:mob_wifi, :frame, :send_error], %{bytes: 5},
                      %{
                        carrier: :wifi_direct,
                        error: %Mob.Wifi.Error{
                          carrier: :wifi_direct,
                          details: nil,
                          peer_id: "peer-1",
                          reason: :native_client_not_configured
                        },
                        peer_id: "peer-1",
                        reason: :native_client_not_configured
                      }}

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
    test "emits canonical transport events and telemetry", %{telemetry_ref: telemetry_ref} do
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
      assert_receive {^telemetry_ref, [:mob_wifi, :peer, :up], %{count: 1}, %{peer_id: "peer-1"}}

      assert_receive {^telemetry_ref, [:mob_wifi, :peer, :discovered], %{count: 1},
                      %{carrier: :wifi_direct, peer_id: "peer-1"}}

      assert_receive {^telemetry_ref, [:mob_wifi, :frame, :received], %{bytes: 5},
                      %{peer_id: "peer-1"}}

      assert_receive {^telemetry_ref, [:mob_wifi, :peer, :down], %{count: 1},
                      %{peer_id: "peer-1"}}

      GenServer.stop(bridge)
    end

    test "emits transport_error for unknown native events", %{telemetry_ref: telemetry_ref} do
      {:ok, bridge} = WifiBridge.start_link(event_target: self())

      assert {:error, {:unknown_native_event, %{bad: true}}} =
               WifiBridge.receive_native_event(bridge, %{bad: true})

      assert_receive {:transport_error, {:unknown_native_event, %{bad: true}}}

      assert_receive {^telemetry_ref, [:mob_wifi, :bridge, :error], %{count: 1},
                      %{
                        error: %Mob.Wifi.Error{
                          carrier: nil,
                          details: %{event: %{bad: true}},
                          peer_id: nil,
                          reason: {:unknown_native_event, %{bad: true}}
                        },
                        reason: {:unknown_native_event, %{bad: true}}
                      }}

      GenServer.stop(bridge)
    end
  end
end
