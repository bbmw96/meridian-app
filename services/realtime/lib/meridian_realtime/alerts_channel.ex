defmodule MeridianRealtime.AlertsChannel do
  use Phoenix.Channel

  require Logger

  @impl true
  def join("alerts:" <> user_id, _params, socket) do
    if socket.assigns.user_id == user_id do
      Phoenix.PubSub.subscribe(MeridianRealtime.PubSub, "alerts:#{user_id}")
      {:ok, assign(socket, :channel_user_id, user_id)}
    else
      {:error, %{reason: "unauthorised: user_id mismatch"}}
    end
  end

  @impl true
  def handle_in("subscribe_alert", payload, socket) do
    with {:ok, pair} <- Map.fetch(payload, "pair"),
         {:ok, threshold} <- Map.fetch(payload, "threshold_rate"),
         {:ok, direction} <- Map.fetch(payload, "direction"),
         true <- is_binary(pair) and String.match?(pair, ~r/^[A-Z]{3}\/[A-Z]{3}$/),
         true <- is_number(threshold) and threshold > 0,
         true <- direction in ["above", "below"] do
      alert_config = %{
        pair: pair,
        threshold_rate: threshold,
        direction: direction,
        user_id: socket.assigns.user_id
      }

      MeridianRealtime.AlertMonitor.register_alert(alert_config)

      {:reply, {:ok, %{status: "subscribed", pair: pair, threshold: threshold, direction: direction}}, socket}
    else
      _ ->
        {:reply,
         {:error, %{reason: "invalid alert config — pair (ABC/XYZ), threshold_rate (number), direction (above|below) required"}},
         socket}
    end
  end

  def handle_in("unsubscribe_alert", payload, socket) do
    with {:ok, pair} <- Map.fetch(payload, "pair") do
      MeridianRealtime.AlertMonitor.deregister_alert(socket.assigns.user_id, pair)
      {:reply, {:ok, %{status: "unsubscribed", pair: pair}}, socket}
    else
      _ ->
        {:reply, {:error, %{reason: "pair is required"}}, socket}
    end
  end

  def handle_in("list_alerts", _payload, socket) do
    alerts = MeridianRealtime.AlertMonitor.list_alerts(socket.assigns.user_id)
    {:reply, {:ok, %{alerts: alerts}}, socket}
  end

  def handle_in(_event, _payload, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:alert_triggered, alert_data}, socket) do
    push(socket, "alert_triggered", alert_data)
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def terminate(_reason, socket) do
    Phoenix.PubSub.unsubscribe(MeridianRealtime.PubSub, "alerts:#{socket.assigns.user_id}")
    {:ok, socket}
  end
end
