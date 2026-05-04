defmodule MeridianRealtime.RateFetcher do
  use GenServer

  require Logger

  @table_name :meridian_rates
  @poll_interval_ms 30_000

  @major_pairs [
    "GBP/USD",
    "EUR/GBP",
    "USD/JPY",
    "AUD/GBP",
    "CAD/GBP",
    "CHF/GBP",
    "CNY/GBP",
    "INR/GBP",
    "GBP/EUR",
    "GBP/JPY",
    "GBP/AUD",
    "GBP/CAD",
    "GBP/CHF",
    "GBP/HKD",
    "GBP/SGD",
    "GBP/NOK",
    "GBP/SEK",
    "GBP/DKK",
    "GBP/NZD",
    "GBP/ZAR",
    "GBP/MXN",
    "GBP/BRL",
    "GBP/KRW",
    "GBP/TRY",
    "GBP/PLN",
    "GBP/CZK",
    "GBP/HUF",
    "USD/GBP"
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_current_rates do
    case :ets.info(@table_name) do
      :undefined ->
        []

      _ ->
        :ets.tab2list(@table_name)
        |> Enum.map(fn {pair, rate_data} ->
          Map.put(rate_data, :pair, pair)
        end)
    end
  end

  def get_rate(pair) when is_binary(pair) do
    case :ets.lookup(@table_name, pair) do
      [{^pair, rate_data}] -> {:ok, rate_data}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def init(_args) do
    :ets.new(@table_name, [:named_table, :public, :set, read_concurrency: true])

    send(self(), :fetch_rates)

    {:ok, %{last_rates: %{}, consecutive_failures: 0}}
  end

  @impl true
  def handle_info(:fetch_rates, state) do
    new_state =
      case fetch_rates_from_api() do
        {:ok, rates} ->
          store_and_broadcast(rates, state.last_rates)
          Process.send_after(self(), :fetch_rates, @poll_interval_ms)
          %{state | last_rates: rates, consecutive_failures: 0}

        {:error, reason} ->
          failures = state.consecutive_failures + 1
          Logger.warning("[RateFetcher] Fetch failed (attempt #{failures}): #{inspect(reason)}")

          retry_delay = min(@poll_interval_ms, failures * 5_000)
          Process.send_after(self(), :fetch_rates, retry_delay)
          %{state | consecutive_failures: failures}
      end

    {:noreply, new_state}
  end

  defp fetch_rates_from_api do
    base_currency = "GBP"
    rate_endpoint = System.get_env("CURRENCY_RATE_ENDPOINT", "https://api.exchangerate-api.com/v4/latest")
    url = "#{rate_endpoint}/#{base_currency}"

    case HTTPoison.get(url, [], timeout: 8_000, recv_timeout: 8_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"rates" => api_rates}} ->
            rates =
              @major_pairs
              |> Enum.reduce(%{}, fn pair, acc ->
                [from, to] = String.split(pair, "/")

                rate =
                  cond do
                    from == base_currency ->
                      Map.get(api_rates, to)

                    to == base_currency ->
                      gbp_to_from = Map.get(api_rates, from)
                      if gbp_to_from && gbp_to_from > 0, do: Float.round(1.0 / gbp_to_from, 6)

                    true ->
                      gbp_to_from = Map.get(api_rates, from)
                      gbp_to_to = Map.get(api_rates, to)

                      if gbp_to_from && gbp_to_to && gbp_to_from > 0 do
                        Float.round(gbp_to_to / gbp_to_from, 6)
                      end
                  end

                if rate do
                  Map.put(acc, pair, %{
                    rate: rate,
                    base: from,
                    quote: to,
                    updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
                  })
                else
                  acc
                end
              end)

            {:ok, rates}

          {:error, decode_err} ->
            {:error, {:json_decode, decode_err}}
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:network, reason}}
    end
  end

  defp store_and_broadcast(new_rates, previous_rates) do
    Enum.each(new_rates, fn {pair, rate_data} ->
      :ets.insert(@table_name, {pair, rate_data})
    end)

    broadcast_payload =
      Enum.map(new_rates, fn {pair, data} ->
        previous = Map.get(previous_rates, pair)

        change_percent =
          if previous && previous.rate && previous.rate > 0 do
            Float.round((data.rate - previous.rate) / previous.rate * 100, 4)
          else
            0.0
          end

        %{
          pair: pair,
          rate: data.rate,
          base_currency: data.base,
          quote_currency: data.quote,
          change_percent: change_percent,
          timestamp: data.updated_at
        }
      end)

    Phoenix.PubSub.broadcast(
      MeridianRealtime.PubSub,
      "currency_rates",
      {:rate_update, broadcast_payload}
    )

    Logger.debug("[RateFetcher] Broadcasted #{length(broadcast_payload)} rate updates")
  end
end
