// El estado y las reglas están en Elixir. Este archivo solo conecta LiveView.
(() => {
  if (!window.Phoenix || !window.LiveView) {
    console.error("Faltan Phoenix y LiveView JS. Ejecuta mix assets.vendor.");
    return;
  }
  const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  const hooks = {
    CopyInvite: {
      mounted() {
        this.onCopy = async () => {
          try {
            await navigator.clipboard.writeText(location.href);
            const label = this.el.querySelector('.share-action');
            if (label) label.textContent = '✓ COPIADO';
          } catch (_) {
            prompt('Copia el enlace de la partida:', location.href);
          }
        };
        this.el.addEventListener('click', this.onCopy);
      },
      destroyed() { this.el.removeEventListener('click', this.onCopy); }
    }
  };
  const socket = new window.LiveView.LiveSocket('/live', window.Phoenix.Socket, {
    params: {_csrf_token: token}, hooks
  });
  socket.connect();
  window.liveSocket = socket;
})();
