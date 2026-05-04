defmodule MeridianRealtime.HealthController do
  use Phoenix.Controller, formats: [:json]

  def index(conn, _params) do
    rate_count = :ets.info(:meridian_rates) |> Keyword.get(:size, 0)

    json(conn, %{
      status: "healthy",
      service: "meridian-realtime",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      rates_cached: rate_count
    })
  end
end
