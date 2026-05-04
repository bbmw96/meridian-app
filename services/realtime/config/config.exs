import Config

config :meridian_realtime, MeridianRealtime.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4001")],
  url: [host: System.get_env("HOST") || "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE") ||
    "YaJuKmXyKhLpZqNcBvDsFgHjWoEiTrUlMnPxAsCdVbGhJkLo5MnPqRsTuVwXy12",
  render_errors: [formats: [json: Phoenix.Controller]],
  pubsub_server: MeridianRealtime.PubSub,
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SALT") || "meridian-live-salt"]

config :phoenix, :json_library, Jason

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :module]

import_config "#{config_env()}.exs"
