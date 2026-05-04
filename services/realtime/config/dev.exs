import Config

config :meridian_realtime, MeridianRealtime.Endpoint,
  http: [port: 4001],
  debug_errors: true,
  code_reloader: false,
  check_origin: false

config :logger, level: :debug
