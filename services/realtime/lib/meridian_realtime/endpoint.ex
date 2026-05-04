defmodule MeridianRealtime.Endpoint do
  use Phoenix.Endpoint, otp_app: :meridian_realtime

  socket "/socket", MeridianRealtime.UserSocket,
    websocket: [
      timeout: 45_000,
      transport_log: false,
      compress: true
    ],
    longpoll: false

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug MeridianRealtime.Router
end
