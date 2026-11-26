defmodule LexicafeWeb.LobbyLive do
  use Phoenix.LiveView
  alias Lexicafe.Games

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, token: session["player_token"], join_code: "")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="lobby page">
      <div class="pixel-kicker">◆ HECHO CON ELIXIR + LIVEVIEW ◆</div>
      <div class="lobby-art" aria-hidden="true"><span>☕</span><span>✦</span><span>ABC</span></div>
      <h1>LEXI<span>CAFÉ</span></h1>
      <p class="lobby-tagline">Un duelo de palabras que se sirve por turnos.</p>
      <div class="rule-pills"><span>11 × 11</span><span>2 TELÉFONOS</span><span>8-BIT</span></div>

      <div class="lobby-panels">
        <div class="panel feature-panel">
          <div class="panel-caption">ELIGE UN MODO</div>
          <button class="pixel-button full primary" phx-click="create" phx-value-mode="duo">
            <span>⚔</span> CREAR SALA PARA 2
            <small>Invita a alguien con un enlace</small>
          </button>
          <button class="pixel-button full secondary" phx-click="create" phx-value-mode="solo">
            <span>♟</span> PRÁCTICA INDIVIDUAL
            <small>Juega a tu ritmo, sin rival</small>
          </button>
        </div>
        <div class="panel join-panel">
          <div class="panel-caption">¿TIENES UN CÓDIGO?</div>
          <form phx-submit="join" class="join-form">
            <input name="code" maxlength="6" minlength="6" placeholder="ABC123" aria-label="Código de sala" autocomplete="off" required />
            <button class="pixel-button tertiary" type="submit">ENTRAR</button>
          </form>
        </div>
      </div>
      <p class="footnote">Letras, café y estrategia. Palabras en español · Diccionario demo ampliable.</p>
      <p :if={@flash["error"]} class="flash error" role="alert">{@flash["error"]}</p>
    </main>
    """
  end

  @impl true
  def handle_event("create", %{"mode" => mode}, socket) do
    case Games.create(mode, socket.assigns.token) do
      {:ok, code} -> {:noreply, push_navigate(socket, to: "/s/#{code}")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, reason)}
    end
  end

  def handle_event("join", %{"code" => raw_code}, socket) do
    code = raw_code |> String.trim() |> String.upcase()
    if String.match?(code, ~r/^[A-HJ-NP-Z2-9]{6}$/) and Games.exists?(code) do
      {:noreply, push_navigate(socket, to: "/s/#{code}")}
    else
      {:noreply, put_flash(socket, :error, "No encontramos esa sala. Revisa el código.")}
    end
  end
end
