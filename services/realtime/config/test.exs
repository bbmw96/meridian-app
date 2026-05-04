import Config

config :meridian_realtime, MeridianRealtime.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warning
