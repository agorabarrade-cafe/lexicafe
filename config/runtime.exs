import Config

config :lexicafe, Lexicafe.Repo,
  url: System.get_env("DATABASE_URL") || "ecto://lexicafe:lexicafe@localhost/lexicafe_#{config_env()}",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

if config_env() == :prod do
  if System.get_env("PHX_SERVER") == "false" do
    config :lexicafe, LexicafeWeb.Endpoint, server: false, secret_key_base: nil
  else
    config :lexicafe, LexicafeWeb.Endpoint,
      secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
      url: [
        host: System.get_env("PHX_HOST") || "localhost",
        port: if(System.get_env("PHX_HTTPS") == "true", do: 443, else: 80),
        scheme: if(System.get_env("PHX_HTTPS") == "true", do: "https", else: "http")
      ],
      http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
      server: true
  end
end
