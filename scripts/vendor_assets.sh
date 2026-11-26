#!/bin/sh
set -eu
mkdir -p priv/static/assets/vendor
for NAME in phoenix phoenix_live_view; do
  SOURCE="deps/$NAME/priv/static/$NAME.min.js"
  DEST="priv/static/assets/vendor/$NAME.min.js"
  if [ ! -f "$SOURCE" ]; then
    echo "Falta $SOURCE. Ejecuta mix deps.get." >&2
    exit 1
  fi
  cp "$SOURCE" "$DEST"
done
printf 'JS de Phoenix y LiveView preparados.\n'
