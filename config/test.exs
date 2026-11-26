import Config
config :lexicafe, Lexicafe.Repo, pool: Ecto.Adapters.SQL.Sandbox, pool_size: 10
config :lexicafe, LexicafeWeb.Endpoint, server: false
config :logger, level: :warning
