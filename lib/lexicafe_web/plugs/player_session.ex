defmodule LexicafeWeb.PlayerSession do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :player_token) do
      conn
    else
      put_session(conn, :player_token, :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false))
    end
  end
end
