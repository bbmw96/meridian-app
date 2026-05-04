defmodule MeridianRealtime.Router do
  use Phoenix.Router, helpers: false

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MeridianRealtime do
    pipe_through :api

    get "/health", HealthController, :index
  end
end
