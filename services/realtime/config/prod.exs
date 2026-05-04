import Config

config :meridian_realtime, MeridianRealtime.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4001")
  ],
  check_origin: [
    System.get_env("ALLOWED_ORIGIN_1") || "http://localhost:3000",
    System.get_env("ALLOWED_ORIGIN_2") || "https://app.meridian.io"
  ],
  server: true

config :logger, level: :info
