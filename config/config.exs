import Config

config :lexicafe, ecto_repos: [Lexicafe.Repo]

config :lexicafe, LexicafeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [html: LexicafeWeb.ErrorHTML], layout: false],
  pubsub_server: Lexicafe.PubSub,
  live_view: [signing_salt: "W7UuKdzL"],
  secret_key_base: String.duplicate("local_dev_lexicafe_secret_key_do_not_use_in_production_", 2),
  http: [ip: {0, 0, 0, 0}, port: 4000],
  server: true

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
