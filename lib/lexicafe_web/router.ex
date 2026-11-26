defmodule LexicafeWeb.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug LexicafeWeb.PlayerSession
    plug :fetch_live_flash
    plug :put_root_layout, html: {LexicafeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    live_session :main, layout: {LexicafeWeb.Layouts, :app} do
      live "/", LexicafeWeb.LobbyLive
      live "/s/:code", LexicafeWeb.GameLive
    end
  end
end
