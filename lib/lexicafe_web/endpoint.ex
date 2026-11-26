defmodule LexicafeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :lexicafe

  @session_options [
    store: :cookie,
    key: "_lexicafe_session",
    signing_salt: "uQ1ePr4a",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  plug Plug.Static, at: "/", from: :lexicafe, gzip: false, only: ~w(assets favicon.ico robots.txt)
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug LexicafeWeb.Router
end
