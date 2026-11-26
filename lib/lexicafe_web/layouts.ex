defmodule LexicafeWeb.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="es-MX">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <meta name="theme-color" content="#22170f" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <meta name="description" content="Lexicafé: duelo de palabras en pixel art, hecho con Phoenix LiveView." />
        <title>Lexicafé · Duelo de palabras</title>
        <link rel="stylesheet" href="/assets/style.css" />
        <script defer src="/assets/vendor/phoenix.min.js"></script>
        <script defer src="/assets/vendor/phoenix_live_view.min.js"></script>
        <script defer src="/assets/app.js"></script>
      </head>
      <body>{@inner_content}</body>
    </html>
    """
  end

  def app(assigns) do
    ~H"""
    <div class="app-shell">{@inner_content}</div>
    """
  end
end
