defmodule LexicafeWeb.GameLive do
  use Phoenix.LiveView
  alias Lexicafe.Games
  alias Lexicafe.Game.{Rules, TileBag}
  alias LexicafeWeb.Presence

  @impl true
  def mount(%{"code" => raw_code}, session, socket) do
    code = String.upcase(raw_code)
    token = session["player_token"]

    case Games.join(code, token) do
      {:ok, game} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Lexicafe.PubSub, Games.topic(code))
          Phoenix.PubSub.subscribe(Lexicafe.PubSub, Games.presence_topic(code))
          Presence.track(self(), Games.presence_topic(code), token, %{connected_at: System.system_time(:second)})
        end

        {:ok,
         socket
         |> assign(code: code, token: token, game: game, draft: %{}, selected: [],
           online: Games.online(code), error: nil)}
      {:error, reason} ->
        {:ok, assign(socket, code: code, token: token, game: nil, error: reason,
          draft: %{}, selected: [], online: [])}
    end
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :move_preview, preview_state(assigns.game, assigns.draft))

    ~H"""
    <main class="game-page page">
      <header class="game-topbar">
        <a href="/" class="back-link" aria-label="Ir al inicio">‹ SALIR</a>
        <div class="brand-small">LEXI<span>CAFÉ</span></div>
        <button :if={@game && @game.mode == "duo"} type="button" id="copy-invite" phx-hook="CopyInvite" class="room-chip room-share-button" aria-label={"Copiar enlace de sala #{@code}"} title="Copiar enlace de invitación">
          <span class="share-code">{@code}</span><span class="share-action"><span aria-hidden="true">⧉</span> COPIAR</span>
        </button>
        <span :if={is_nil(@game) or @game.mode == "solo"} class="room-chip">{@code}</span>
      </header>

      <%= if @game do %>
        <section class="game-heading">
          <div class="game-kicker">PALABRAS · PIXELES · CAFÉ</div>
          <h1>{if @game.mode == "solo", do: "PRÁCTICA", else: "DUELO DE PALABRAS"}</h1>
        </section>

        <section class="scoreboard" aria-label="Puntuación">
          <%= for player <- @game.players do %>
            <div
              class={["player-card", if(@game.active_seat == player.seat and @game.status == "playing", do: "on-turn", else: "off-turn")]}
              aria-label={"#{player.name}: #{player.score} puntos"}
            >
              <div class="player-label">
                {player.name}
                <span :if={player.me}>(TÚ)</span>
                <small :if={@game.mode == "duo"} class={if(Enum.at(@online, player.seat, false), do: "online", else: "offline")}></small>
              </div>
              <div class="player-stat-row">
                <strong class="player-score">{player.score}</strong>
                <span class="score-caption">PUNTOS</span>
                <span :if={@game.active_seat == player.seat and @game.status == "playing"} class="turn-tag">TURNO</span>
              </div>
            </div>
          <% end %>
          <div :if={@game.mode == "solo"} class="solo-note">OBJETIVO: crea todas las palabras que puedas.</div>
        </section>

        <div :if={@game.status == "waiting"} class="banner waiting" role="status">
          Esperando al segundo jugador. Comparte el código <strong>{@code}</strong>.
        </div>
        <div :if={@game.status == "finished"} class="banner finished" role="status">
          PARTIDA TERMINADA · {winner_label(@game)}
        </div>
        <div class="invite-row solo-invite"><span>FICHAS EN LA BOLSA <strong>{@game.bag_count}</strong></span></div>

        <section class="board-panel" aria-label="Tablero de 11 por 11">
          <div class="board-grid">
            <%= for {_value, index} <- Enum.with_index(@game.board) do %>
              <% letter = tile_at(@game, @draft, index) %>
              <% provisional = Map.has_key?(@draft, index) %>
              <button
                type="button"
                id={"cell-#{index}"}
                phx-click="cell"
                phx-value-pos={index}
                disabled={not @game.my_turn or (not provisional and is_nil(letter) and @selected == [])}
                class={["board-cell", bonus_class(index), if(letter, do: "occupied", else: ""), if(provisional, do: "provisional", else: "")]}
                aria-label={cell_label(letter, index, provisional)}
              >
                <%= if letter do %>
                  <span class="letter-tile">
                    <b>{letter}</b><small>{TileBag.points(letter)}</small>
                  </span>
                <% else %>
                  <span class="bonus-label">{bonus_label(index)}</span>
                <% end %>
              </button>
            <% end %>
          </div>
          <div class="bonus-legend"><span>2L/3L = LETRA</span><span>2P/3P = PALABRA</span><span>★ = CENTRO</span></div>
        </section>

        <section class="rack-panel" aria-label="Tus fichas">
          <div class="rack-heading"><span>TUS LETRAS</span><span>{map_size(@draft)} colocadas · {length(@selected)} seleccionadas</span></div>
          <div class="tile-rack">
            <%= for {letter, index} <- Enum.with_index(@game.rack) do %>
              <button
                id={"rack-#{index}"}
                type="button"
                phx-click="select"
                phx-value-index={index}
                disabled={not @game.my_turn or rack_used?(@draft, index)}
                class={["rack-tile", if(index in @selected, do: "selected", else: ""), if(List.last(@selected) == index, do: "active-selection", else: ""), if(rack_used?(@draft, index), do: "used", else: "")]}
                aria-label={"Seleccionar #{letter}, #{TileBag.points(letter)} puntos"}
              >
                <span>{letter}</span><small>{TileBag.points(letter)}</small>
              </button>
            <% end %>
          </div>
          <div id="move-preview" class={["move-preview", Atom.to_string(@move_preview.kind)]} role="status" aria-live="polite" aria-atomic="true">
            <%= if @move_preview.kind == :valid do %>
              <span class="preview-symbol" aria-hidden="true">✓</span>
              <div class="preview-description">
                <span class="preview-eyebrow">PALABRA VÁLIDA</span>
                <strong class="preview-word">{Enum.join(@move_preview.words, " + ")}</strong>
                <span class="preview-detail">Puntuación estimada de la jugada</span>
              </div>
              <div class="preview-points"><strong>+{@move_preview.score}</strong><span>PUNTOS</span></div>
            <% else %>
              <span class="preview-symbol" aria-hidden="true">{if(@move_preview.kind == :invalid, do: "!", else: "?")}</span>
              <div class="preview-description">
                <span class="preview-eyebrow">{if(@move_preview.kind == :invalid, do: "JUGADA NO VÁLIDA", else: "VISTA PREVIA")}</span>
                <strong class="preview-word">{if(@move_preview.kind == :invalid, do: @move_preview.letters, else: "FORMA UNA PALABRA")}</strong>
                <span class="preview-detail">{if(@move_preview.kind == :invalid, do: @move_preview.reason, else: "Coloca letras en el tablero para calcular sus puntos.")}</span>
              </div>
              <div class="preview-points"><strong>—</strong><span>PUNTOS</span></div>
            <% end %>
          </div>
          <button type="button" class="pixel-button primary play-word-button" phx-click="commit" disabled={not @game.my_turn or @move_preview.kind != :valid}>JUGAR PALABRA <span aria-hidden="true">➜</span></button>
          <div class="secondary-actions" role="group" aria-label="Acciones secundarias">
            <button type="button" class="secondary-action pass-action" phx-click="pass" disabled={not @game.my_turn}>
              <span aria-hidden="true" class="action-icon">↷</span><span>PASAR<br/>TURNO</span>
            </button>
            <button type="button" class="secondary-action exchange-action" phx-click="exchange" disabled={not @game.my_turn or @selected == [] or map_size(@draft) > 0 or @game.bag_count < length(@selected)} aria-label={"Cambiar #{length(@selected)} letras seleccionadas"}>
              <span aria-hidden="true" class="action-icon">⇄</span><span>CAMBIAR<br/>LETRAS <small>({length(@selected)})</small></span>
            </button>
            <button type="button" class="secondary-action clear-action" phx-click="clear" disabled={not @game.my_turn or (map_size(@draft) == 0 and @selected == [])}>
              <span aria-hidden="true" class="action-icon">×</span><span>BORRAR<br/>SELECCIÓN</span>
            </button>
          </div>
          <details class="help-details">
            <summary>¿CÓMO COLOCAR LAS LETRAS?</summary>
            <p>Selecciona una o varias letras en tu atril y luego toca una casilla libre del tablero. Se coloca la última letra seleccionada. Toca una casilla provisional para devolver esa letra al atril. Las letras ya confirmadas no se pueden retirar.</p>
          </details>
        </section>

        <div :if={@game.last} class="last-move" role="status">
          <span>ÚLTIMA JUGADA</span>
          <strong>{Enum.join(@game.last["words"], " · ")}</strong>
          <b>+{@game.last["points"]}</b>
        </div>
        <p :if={@flash["error"]} class="flash error" role="alert">{@flash["error"]}</p>
        <p :if={@flash["info"]} class="flash info" role="status">{@flash["info"]}</p>
      <% else %>
        <div class="panel not-found">
          <h1>NO SE PUDO ABRIR LA SALA</h1>
          <p>{@error}</p>
          <a href="/" class="pixel-button primary">VOLVER AL INICIO</a>
        </div>
      <% end %>
    </main>
    """
  end

  @impl true
  def handle_event("select", %{"index" => raw}, socket) do
    with {:ok, index} <- parse_int(raw),
         true <- socket.assigns.game.my_turn,
         true <- index >= 0 and index < length(socket.assigns.game.rack),
         false <- rack_used?(socket.assigns.draft, index) do
      next =
        if index in socket.assigns.selected do
          List.delete(socket.assigns.selected, index)
        else
          socket.assigns.selected ++ [index]
        end

      {:noreply, socket |> assign(selected: next) |> clear_flash(:error)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("cell", %{"pos" => raw}, socket) do
    with {:ok, pos} <- parse_int(raw),
         true <- pos in 0..120,
         true <- socket.assigns.game.my_turn do
      draft = socket.assigns.draft
      cond do
        Map.has_key?(draft, pos) ->
          {:noreply, socket |> assign(draft: Map.delete(draft, pos)) |> clear_flash(:error)}
        Enum.at(socket.assigns.game.board, pos) != nil -> {:noreply, socket}
        socket.assigns.selected == [] ->
          # La última letra seleccionada se consume al colocarla. No lanzar un error
          # obsoleto al tocar otra casilla sin letras pendientes.
          {:noreply, socket}
        true ->
          index = List.last(socket.assigns.selected)
          {:noreply, socket
            |> assign(draft: Map.put(draft, pos, index),
              selected: List.delete(socket.assigns.selected, index))
            |> clear_flash(:error)}
      end
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("clear", _params, socket) do
    {:noreply, socket |> assign(draft: %{}, selected: []) |> clear_flash(:error)}
  end

  def handle_event("commit", _params, socket) do
    placements = Enum.map(socket.assigns.draft, fn {pos, index} -> %{"pos" => pos, "rack_index" => index} end)
    apply_move(socket, Games.place(socket.assigns.code, socket.assigns.token, placements))
  end

  def handle_event("pass", _params, socket) do
    apply_move(socket, Games.pass(socket.assigns.code, socket.assigns.token))
  end

  def handle_event("exchange", _params, socket) do
    indices = socket.assigns.selected
    if indices == [] or map_size(socket.assigns.draft) > 0 do
      {:noreply, put_flash(socket, :error, "Selecciona las letras que quieras cambiar, sin colocarlas." )}
    else
      apply_move(socket, Games.exchange(socket.assigns.code, socket.assigns.token, indices))
    end
  end

  @impl true
  def handle_info(:game_updated, socket) do
    case Games.snapshot(socket.assigns.code, socket.assigns.token) do
      {:ok, game} ->
        reset_draft? = game.version != socket.assigns.game.version
        socket = if reset_draft?, do: assign(socket, draft: %{}, selected: []), else: socket
        {:noreply, socket |> assign(game: game, online: Games.online(socket.assigns.code)) |> clear_flash(:error)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, online: Games.online(socket.assigns.code))}
  end

  defp apply_move(socket, {:ok, game}) do
    {:noreply,
     socket
     |> assign(game: game, draft: %{}, selected: [])
     |> clear_flash()}
  end

  defp apply_move(socket, {:error, reason}), do: {:noreply, put_flash(socket, :error, reason)}

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :invalid}
    end
  end
  defp parse_int(_), do: {:error, :invalid}

  defp tile_at(game, draft, index) do
    case Map.fetch(draft, index) do
      {:ok, rack_index} -> Enum.at(game.rack, rack_index)
      :error ->
        case Enum.at(game.board, index) do
          nil -> nil
          tile -> tile["letter"]
        end
    end
  end

  defp rack_used?(draft, index), do: Enum.any?(draft, fn {_pos, rack_i} -> rack_i == index end)

  defp preview_state(_game, draft) when map_size(draft) == 0, do: %{kind: :empty}
  defp preview_state(nil, _draft), do: %{kind: :empty}

  defp preview_state(game, draft) do
    placements = Enum.map(draft, fn {pos, i} ->
      {pos, %{"letter" => Enum.at(game.rack, i)}}
    end)

    case Rules.evaluate(game.board, placements) do
      {:ok, result} -> %{kind: :valid, words: result.words, score: result.score}
      {:error, reason} ->
        letters =
          draft
          |> Enum.sort_by(fn {pos, _} -> pos end)
          |> Enum.map_join("", fn {_pos, i} -> Enum.at(game.rack, i) end)

        %{kind: :invalid, letters: letters, reason: reason}
    end
  end

  defp bonus_class(pos) do
    case Rules.bonus(pos) do
      "TW" -> "bonus-tw"
      "DW" -> "bonus-dw"
      "TL" -> "bonus-tl"
      "DL" -> "bonus-dl"
      nil -> ""
    end
  end

  defp bonus_label(pos) do
    case Rules.bonus(pos) do
      "TW" -> "3P"
      "DW" -> if(pos == Rules.center(), do: "★", else: "2P")
      "TL" -> "3L"
      "DL" -> "2L"
      nil -> ""
    end
  end

  defp cell_label(nil, pos, _), do: "Casilla #{pos + 1}: #{bonus_label(pos)}"
  defp cell_label(letter, pos, provisional), do: "Casilla #{pos + 1}: #{letter}#{if provisional, do: " (sin confirmar)", else: ""}"

  defp winner_label(game) do
    sorted = Enum.sort_by(game.players, & &1.score, :desc)
    case sorted do
      [first, second] when first.score == second.score -> "EMPATE"
      [first | _] -> "GANA #{String.upcase(first.name)}"
      [] -> "FIN"
    end
  end
end
