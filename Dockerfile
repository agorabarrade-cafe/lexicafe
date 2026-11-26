FROM elixir:1.19
WORKDIR /app
ENV MIX_ENV=dev PORT=4000
RUN apt-get update && apt-get install -y --no-install-recommends build-essential git ca-certificates python3 && rm -rf /var/lib/apt/lists/*
RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs ./
COPY config ./config
RUN mix deps.get
COPY . .
RUN python3 scripts/build_dictionary.py && mix assets.vendor && mix compile
EXPOSE 4000
CMD ["sh", "-c", "mix ecto.create && mix ecto.migrate && exec mix phx.server"]
