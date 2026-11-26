defmodule LexicafeWeb.Presence do
  use Phoenix.Presence, otp_app: :lexicafe, pubsub_server: Lexicafe.PubSub
end
