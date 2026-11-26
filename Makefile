RELEASE_BIN := _build/prod/rel/lexicafe/bin/lexicafe

.PHONY: release migrate start

release:
	MIX_ENV=prod mix deps.get --only prod
	MIX_ENV=prod mix assets.vendor
	MIX_ENV=prod mix compile
	MIX_ENV=prod mix release --overwrite

migrate:
	@: "$${DATABASE_URL:?Define DATABASE_URL para ejecutar las migraciones}"
	MIX_ENV=prod PHX_SERVER=false mix ecto.migrate

start:
	@test -x "$(RELEASE_BIN)" || { echo "Ejecuta make release primero." >&2; exit 1; }
	@: "$${DATABASE_URL:?Define DATABASE_URL para iniciar el release}"
	@: "$${SECRET_KEY_BASE:?Define SECRET_KEY_BASE para iniciar el release}"
	@: "$${PHX_HOST:?Define PHX_HOST para iniciar el release}"
	PHX_SERVER=true "$(RELEASE_BIN)" start
