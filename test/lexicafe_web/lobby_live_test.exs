defmodule LexicafeWeb.LobbyLiveTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Ecto.Adapters.SQL.Sandbox
  @endpoint LexicafeWeb.Endpoint

  setup do
    :ok = Sandbox.checkout(Lexicafe.Repo)
    Sandbox.mode(Lexicafe.Repo, {:shared, self()})
    :ok
  end

  test "el lobby sirve botones de partida y la sala se puede abrir" do
    conn = Plug.Test.init_test_session(build_conn(), %{player_token: "test-owner-123"})
    {:ok, view, html} = live(conn, "/")
    assert html =~ "LEXI"
    assert html =~ "CREAR SALA PARA 2"
    assert {:error, {:live_redirect, %{to: path}}} = view |> element("button[phx-value-mode=solo]") |> render_click()
    assert String.starts_with?(path, "/s/")
    {:ok, _game, game_html} = live(conn, path)
    assert game_html =~ "PRACTICA" or game_html =~ "PRÁCTICA"
    assert game_html =~ "cell-60"
    assert game_html =~ "JUGAR PALABRA"
    assert game_html =~ "PASAR"
    assert game_html =~ "CAMBIAR"
    assert game_html =~ "BORRAR"
    assert game_html =~ "TURNO"
    assert game_html =~ "FORMA UNA PALABRA"
  end
  test "puede seleccionar y cambiar dos letras en una acción secundaria" do
    conn = Plug.Test.init_test_session(build_conn(), %{player_token: "test-exchange-123"})
    {:ok, lobby, _html} = live(conn, "/")
    assert {:error, {:live_redirect, %{to: path}}} =
      lobby |> element("button[phx-value-mode=solo]") |> render_click()
    {:ok, game, _html} = live(conn, path)

    game |> element("#rack-0") |> render_click()
    game |> element("#rack-1") |> render_click()
    assert render(game) =~ "2 seleccionadas"
    game |> element("button[phx-click=exchange]") |> render_click()
    assert render(game) =~ "CAMBIÓ 2 FICHAS"
    assert render(game) =~ "0 seleccionadas"
  end

  test "la vista previa enseña un motivo de invalidez antes de confirmar" do
    conn = Plug.Test.init_test_session(build_conn(), %{player_token: "test-preview-123"})
    {:ok, lobby, _html} = live(conn, "/")
    assert {:error, {:live_redirect, %{to: path}}} =
      lobby |> element("button[phx-value-mode=solo]") |> render_click()
    {:ok, game, _html} = live(conn, path)

    game |> element("#rack-0") |> render_click()
    game |> element("#cell-60") |> render_click()
    assert has_element?(game, "#move-preview.invalid")
    assert render(game) =~ "JUGADA NO VÁLIDA"
    assert render(game) =~ "Debes formar una palabra"
    game |> element("button[phx-click=clear]") |> render_click()
    assert has_element?(game, "#move-preview.empty")
  end

  test "el codigo de sala y el enlace comparten un boton en el encabezado" do
    conn = Plug.Test.init_test_session(build_conn(), %{player_token: "test-share-123"})
    {:ok, lobby, _} = live(conn, "/")
    assert {:error, {:live_redirect, %{to: path}}} =
      lobby |> element("button[phx-value-mode=duo]") |> render_click()

    {:ok, game, _} = live(conn, path)
    assert has_element?(game, "#copy-invite.room-share-button")
    assert has_element?(game, "#copy-invite .share-code")
    assert has_element?(game, "#copy-invite .share-action")
    refute has_element?(game, ".invite-row #copy-invite")
  end

  test "sin letra pendiente no aparece una alerta de seleccion obsoleta" do
    conn = Plug.Test.init_test_session(build_conn(), %{player_token: "test-select-no-flash-123"})
    {:ok, lobby, _} = live(conn, "/")
    assert {:error, {:live_redirect, %{to: path}}} =
      lobby |> element("button[phx-value-mode=solo]") |> render_click()

    {:ok, game, _} = live(conn, path)
    assert has_element?(game, "#cell-60[disabled]")
    game |> element("#rack-0") |> render_click()
    refute has_element?(game, "#cell-60[disabled]")
    game |> element("#cell-60") |> render_click()
    assert has_element?(game, "#cell-61[disabled]")
    refute render(game) =~ "Selecciona primero una letra"
    refute render(game) =~ "Diccionario local DEMO"
    assert has_element?(game, ".help-details summary")
  end

end
