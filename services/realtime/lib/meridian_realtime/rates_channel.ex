defmodule MeridianRealtime.RatesChannel do
  use Phoenix.Channel

  require Logger

  @impl true
  def join("rates:lobby", _params, socket) do
    Phoenix.PubSub.subscribe(MeridianRealtime.PubSub, "currency_rates")

    current_rates = MeridianRealtime.RateFetcher.get_current_rates()

    send(self(), {:after_join, current_rates})

    {:ok, socket}
  end

  def join("rates:" <> _topic, _params, _socket) do
    {:error, %{reason: "only rates:lobby is supported"}}
  end

  @impl true
  def handle_info({:after_join, rates}, socket) do
    push(socket, "rate_snapshot", %{rates: rates, timestamp: utc_now_iso()})
    {:noreply, socket}
  end

  def handle_info({:rate_update, rates}, socket) do
    push(socket, "rate_update", %{rates: rates, timestamp: utc_now_iso()})
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{pong: true}}, socket}
  end

  def handle_in(_event, _payload, socket), do: {:noreply, socket}

  @impl true
  def terminate(_reason, socket) do
    Phoenix.PubSub.unsubscribe(MeridianRealtime.PubSub, "currency_rates")
    {:ok, socket}
  end

  defp utc_now_iso do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
