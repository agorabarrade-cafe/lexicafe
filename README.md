# LEXICAFÉ — MVP Phoenix LiveView v1.2

Juego original de palabras en español, estética 8 bits, tablero de **11 × 11**, modalidad individual y **dos personas en dos teléfonos diferentes**. El estado se resuelve en un `GenServer` y se difunde mediante **Phoenix.LiveView + PubSub**; no se programaron Phoenix Channels personalizados ni se usa Python en ejecución.

## Comenzar con Docker (recomendado)

Requisitos: Docker y Docker Compose, con acceso a Internet en la primera compilación.

```bash
unzip lexicafe-liveview-mvp.zip
cd lexicafe-liveview-mvp
docker compose up --build
```

Abre **http://localhost:4000**. La primera compilación instala dependencias de Hex, descarga y prepara el **diccionario ampliado** con Python 3 (solo durante el build), y compila el proyecto. Compose levanta PostgreSQL automáticamente y ejecuta las migraciones. Una vez instalado, la validación de palabras es local y no requiere acceso a Internet.

### Dos teléfonos

1. Desde el primer teléfono, abre la URL del servidor y elige **CREAR SALA PARA 2**.
2. Pulsa el botón con el **código de la sala + COPIAR** que aparece arriba a la derecha y envía el enlace al otro teléfono.
3. El segundo jugador abre el enlace en otro navegador/dispositivo y se une automáticamente.
4. Por turnos, cada persona elige una o varias letras de su atril y después toca las casillas. Pulsa **JUGAR PALABRA** cuando la vista previa muestre una palabra válida.

**Importante:** `localhost` sólo funciona desde la máquina del servidor. En la misma red Wi-Fi, usa `http://IP_LOCAL_DEL_SERVIDOR:4000`. Desde redes diferentes, publica el servidor bajo un dominio con **HTTPS + WebSocket (WSS)**, apuntando el proxy inverso al puerto 4000. En producción configura `PHX_HOST`, `PHX_HTTPS=true`, `SECRET_KEY_BASE` y credenciales de PostgreSQL; no expongas el compose de desarrollo a Internet sin endurecimiento.

**Prueba de privacidad:** para jugar como dos personas diferentes, usa dos dispositivos/navegadores con cookies distintas; dos pestañas del mismo navegador comparten la identidad.

## Ajustes de interfaz v1.2

- **Código de sala y copia de enlace en un solo control:** en modo dúo, el código se muestra arriba a la derecha como un botón que copia el enlace. Ya no hay una fila duplicada debajo del marcador.
- **Marcadores compactos:** nombre del jugador en una línea, y en la siguiente, **número · PUNTOS · TURNO**, con resalte verde del jugador activo.
- **Ayuda plegada:** las instrucciones extensas se movieron a **¿CÓMO COLOCAR LAS LETRAS?**, debajo de los controles. Está cerrada por defecto.
- **Vista previa más grande:** palabra validada y puntuación con tipografía más visible; los errores de validación aparecen dentro del mismo cuadro.
- **Botones secundarios más claros:** **PASAR TURNO** (café), **CAMBIAR LETRAS** (turquesa) y **BORRAR SELECCIÓN** (terracota), con iconos y textos más grandes; **JUGAR PALABRA** sigue siendo la única acción principal.
- **Aviso obsoleto eliminado:** al seleccionar, colocar, retirar o limpiar letras se borra el error anterior; si no hay letras pendientes de colocar, no se emite el mensaje engañoso “Selecciona primero una letra”. Las casillas vacías permanecen deshabilitadas hasta escoger una letra.
- **Sin la leyenda de diccionario al pie** del tablero.

## Diccionario ampliado

La versión anterior incluía aproximadamente **1,200 palabras**. En v1.2, la compilación Docker descarga la lista de **50,000 entradas de frecuencia en español** de [doozan/spanish_data](https://github.com/doozan/spanish_data), extrae las palabras, conserva `Ñ` como letra independiente, elimina tildes de vocales, filtra términos de 2 a 11 letras y une la lista con la demo. El número final de palabras válidas se muestra durante el build. No se incluye el archivo ampliado descargado en el ZIP.

La fuente está publicada con licencia **CC BY 4.0**; su atribución y las modificaciones se documentan en [`priv/dictionary/ATTRIBUTION.md`](priv/dictionary/ATTRIBUTION.md). Es un léxico de uso general orientado a frecuencia, **no un diccionario normativo ni competitivo**, y puede contener nombres, préstamos, conjugaciones o vocablos discutibles. Para producción competitiva convendría curarlo y definir las reglas lingüísticas y regionales.

Para instalar el diccionario fuera de Docker, antes de iniciar Phoenix:

```bash
python3 scripts/build_dictionary.py
```

Si tu máquina no tiene acceso a Internet, puedes usar `--source-file` con una copia previa de `es_merged_50k.txt`. Si no existe `priv/dictionary/es_lexicafe_extended.txt`, el juego utiliza automáticamente el diccionario demo (1,200+ términos).

## Reglas del MVP

- Cada jugador tiene **7 letras**. La bolsa repone letras tras una jugada válida.
- Selecciona una letra y toca una casilla. Repite hasta formar la palabra. Puedes deshacer tocando una casilla provisional o usando **BORRAR** para limpiar la jugada y la selección.
- La primera jugada debe **cubrir la casilla central** y crear una palabra de al menos 2 letras.
- Todas las letras nuevas de una jugada deben estar **alineadas** horizontal o verticalmente, sin espacios vacíos entre ellas.
- En turnos siguientes, toda jugada conecta con letras existentes y **todas las palabras cruzadas formadas** deben ser válidas.
- `2L`, `3L`: multiplican el valor de una letra; `2P`, `3P`: multiplican la puntuación de la palabra. Los bonos sólo se activan cuando se coloca la ficha por primera vez.
- Si se usan las siete fichas en una jugada, se otorgan **35 puntos extra** (regla original de este MVP).
- **PASAR TURNO** salta el turno. El duelo termina después de cuatro pases/cambios consecutivos; el modo solo, tras dos. También termina al vaciar la bolsa y el atril del jugador que acaba de jugar.
- **CAMBIAR LETRAS** reemplaza todas las fichas seleccionadas (una o varias) si la bolsa tiene suficientes letras; consume un turno. En el atril puedes seleccionar varias tocándolas; para colocar se utiliza la última seleccionada.
- La bolsa y los valores de letras son una adaptación original; no replican exactamente las frecuencias de Scrabble ni Apalabrados.
- **Diccionario ampliado al construir con Docker:** se genera una lista local basada en 50,000 entradas de frecuencia; omite tildes y distingue `Ñ` de `N`. No garantiza que todas sus entradas estén aceptadas en torneos.
- No hay comodines, reloj competitivo, bots ni ranking global en este primer MVP.

## Ejecutar con Elixir local

Requisitos: Elixir 1.18+, PostgreSQL local iniciado, Git y compilador C. Por ejemplo:

```bash
export DATABASE_URL='ecto://lexicafe:lexicafe@localhost/lexicafe_dev'
mix local.hex --force
mix local.rebar --force
mix deps.get
python3 scripts/build_dictionary.py
mix ecto.create
mix ecto.migrate
mix assets.vendor
mix phx.server
```

Abre http://localhost:4000.

## Pruebas

Con PostgreSQL disponible y una base de test accesible:

```bash
MIX_ENV=test DATABASE_URL='ecto://lexicafe:lexicafe@localhost/lexicafe_test' mix deps.get
MIX_ENV=test DATABASE_URL='ecto://lexicafe:lexicafe@localhost/lexicafe_test' mix ecto.create
MIX_ENV=test DATABASE_URL='ecto://lexicafe:lexicafe@localhost/lexicafe_test' mix ecto.migrate
MIX_ENV=test DATABASE_URL='ecto://lexicafe:lexicafe@localhost/lexicafe_test' mix test
```

Con Compose ejecutándose:

```bash
docker compose exec -e MIX_ENV=test -e DATABASE_URL=ecto://lexicafe:lexicafe@db/lexicafe_test app sh -lc 'mix ecto.create && mix ecto.migrate && mix test' 
```

Se incluyen pruebas para reglas, cruces, puntuación, turno, bolsa, privacidad del atril, renderizado LiveView y cambios múltiples de letras.

## Estructura

```text
lib/lexicafe/game/
  rules.ex           # Alineación, continuidad, cruces y puntuaciones
  dictionary.ex      # Léxico local cargado y cacheado en el servidor
  tile_bag.ex        # Bolsa y valor de letras
  engine.ex          # Reglas puras y turnos
  server.ex          # GenServer autoritativo, serializa y persiste jugadas
  match.ex           # Esquema Ecto
lib/lexicafe/games.ex     # Contexto de partidas y salas
lib/lexicafe_web/live/
  lobby_live.ex      # Inicio, creación e ingreso
  game_live.ex       # Tablero, atril y jugadas en HEEx
priv/dictionary/es_mx_demo.txt
priv/dictionary/ATTRIBUTION.md
scripts/build_dictionary.py
priv/static/assets/style.css
priv/repo/migrations/
```

### Arquitectura

Cada partida en curso tiene un `Lexicafe.Game.Server` supervisado dinámicamente; `Registry` localiza el proceso por código. El `GenServer` guarda el estado autoritativo y los cambios se persisten en PostgreSQL mediante Ecto. Phoenix PubSub anuncia que el estado cambió; cada LiveView vuelve a solicitar un **snapshot que sólo incluye su propio atril**. `Phoenix.Presence` permite mostrar quién está conectado. La sesión del jugador vive en una cookie firmada del navegador.

**Escalabilidad:** la implementación es de *una sola instancia* Phoenix. Para varios nodos o partidas asíncronas de gran escala se necesita un mecanismo distribuido de coordinación y bloqueo de salas, no basta con levantar varias réplicas detrás de un balanceador.

## Validación / limitaciones de esta entrega

Este repositorio fue creado en un entorno sin la herramienta `elixir` ni Docker, por lo que **no se pudo ejecutar el compilador de Phoenix ni una sesión real de dos teléfonos aquí**. Se incluyen fuentes, pruebas ExUnit e instrucciones para reproducir la verificación en un equipo con Docker. No debe considerarse una versión ya validada en producción.

## Licencias / identidad visual

Juego de mecánica genérica, nombre, interfaz y componentes originales. No incluye nombres comerciales, gráficos ni diccionarios propietarios de Scrabble o Apalabrados. El léxico demo se redactó específicamente para este MVP. El léxico ampliado se prepara durante el build a partir de una fuente externa CC BY 4.0, con atribución incluida. El diccionario se usa exclusivamente en servidor.
