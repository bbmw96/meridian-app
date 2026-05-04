defmodule MeridianRealtime.UserSocket do
  use Phoenix.Socket

  channel "rates:*", MeridianRealtime.RatesChannel
  channel "alerts:*", MeridianRealtime.AlertsChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_token(token) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, reason} ->
        require Logger
        Logger.warning("[UserSocket] Connection rejected: #{reason}")
        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"

  defp verify_token(token) when is_binary(token) and byte_size(token) > 0 do
    secret = System.get_env("JWT_SECRET", "change-me-in-production")

    case decode_jwt(token, secret) do
      {:ok, claims} ->
        user_id = Map.get(claims, "user_id") || Map.get(claims, "sub")

        if user_id do
          {:ok, user_id}
        else
          {:error, "missing user_id claim"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp verify_token(_), do: {:error, "token is empty or invalid"}

  defp decode_jwt(token, secret) do
    with [header_b64, payload_b64, signature_b64] <- String.split(token, "."),
         {:ok, payload_json} <- Base.url_decode64(payload_b64, padding: false),
         {:ok, claims} <- Jason.decode(payload_json),
         signing_input <- "#{header_b64}.#{payload_b64}",
         expected_sig <- :crypto.mac(:hmac, :sha256, secret, signing_input),
         {:ok, provided_sig} <- Base.url_decode64(signature_b64, padding: false),
         true <- :crypto.hash_equals(expected_sig, provided_sig) do
      exp = Map.get(claims, "exp")

      if exp && System.os_time(:second) > exp do
        {:error, "token expired"}
      else
        {:ok, claims}
      end
    else
      false -> {:error, "invalid signature"}
      _ -> {:error, "malformed token"}
    end
  end
end
