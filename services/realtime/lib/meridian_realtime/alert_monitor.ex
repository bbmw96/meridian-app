defmodule MeridianRealtime.AlertMonitor do
  use GenServer

  require Logger

  @dedup_table :meridian_alert_dedup
  @dedup_window_ms 600_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register_alert(alert_config) do
    GenServer.cast(__MODULE__, {:register, alert_config})
  end

  def deregister_alert(user_id, pair) do
    GenServer.cast(__MODULE__, {:deregister, user_id, pair})
  end

  def list_alerts(user_id) do
    GenServer.call(__MODULE__, {:list, user_id})
  end

  @impl true
  def init(_args) do
    :ets.new(@dedup_table, [:named_table, :public, :set, write_concurrency: true])

    Phoenix.PubSub.subscribe(MeridianRealtime.PubSub, "currency_rates")

    {:ok, %{alerts: []}}
  end

  @impl true
  def handle_cast({:register, alert_config}, state) do
    user_id = alert_config.user_id
    pair = alert_config.pair

    filtered =
      Enum.reject(state.alerts, fn a ->
        a.user_id == user_id and a.pair == pair
      end)

    new_alerts = [alert_config | filtered]

    Logger.debug("[AlertMonitor] Registered alert for #{user_id} - #{pair} #{alert_config.direction} #{alert_config.threshold_rate}")

    {:noreply, %{state | alerts: new_alerts}}
  end

  def handle_cast({:deregister, user_id, pair}, state) do
    new_alerts =
      Enum.reject(state.alerts, fn a ->
        a.user_id == user_id and a.pair == pair
      end)

    Logger.debug("[AlertMonitor] Deregistered alert for #{user_id} - #{pair}")

    {:noreply, %{state | alerts: new_alerts}}
  end

  @impl true
  def handle_call({:list, user_id}, _from, state) do
    user_alerts =
      state.alerts
      |> Enum.filter(&(&1.user_id == user_id))
      |> Enum.map(fn a ->
        %{pair: a.pair, threshold_rate: a.threshold_rate, direction: a.direction}
      end)

    {:reply, user_alerts, state}
  end

  @impl true
  def handle_info({:rate_update, rates}, state) do
    rates_map =
      Map.new(rates, fn r ->
        {r.pair, r.rate}
      end)

    now_ms = System.monotonic_time(:millisecond)

    Enum.each(state.alerts, fn alert ->
      case Map.get(rates_map, alert.pair) do
        nil ->
          :skip

        current_rate ->
          threshold_crossed? =
            case alert.direction do
              "above" -> current_rate >= alert.threshold_rate
              "below" -> current_rate <= alert.threshold_rate
              _ -> false
            end

          if threshold_crossed? do
            dedup_key = {alert.user_id, alert.pair, alert.direction}

            already_notified =
              case :ets.lookup(@dedup_table, dedup_key) do
                [{^dedup_key, triggered_at}] ->
                  now_ms - triggered_at < @dedup_window_ms

                [] ->
                  false
              end

            unless already_notified do
              :ets.insert(@dedup_table, {dedup_key, now_ms})

              payload = %{
                pair: alert.pair,
                threshold_rate: alert.threshold_rate,
                direction: alert.direction,
                current_rate: current_rate,
                triggered_at: DateTime.utc_now() |> DateTime.to_iso8601()
              }

              Phoenix.PubSub.broadcast(
                MeridianRealtime.PubSub,
                "alerts:#{alert.user_id}",
                {:alert_triggered, payload}
              )

              Logger.info("[AlertMonitor] Alert triggered for #{alert.user_id} - #{alert.pair} #{alert.direction} #{alert.threshold_rate} (current: #{current_rate})")
            end
          end
      end
    end)

    purge_stale_dedup_entries(now_ms)

    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp purge_stale_dedup_entries(now_ms) do
    stale_keys =
      :ets.tab2list(@dedup_table)
      |> Enum.filter(fn {_key, triggered_at} ->
        now_ms - triggered_at >= @dedup_window_ms
      end)
      |> Enum.map(fn {key, _} -> key end)

    Enum.each(stale_keys, &:ets.delete(@dedup_table, &1))
  end
end
