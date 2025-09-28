{ pkgs }:

pkgs.mkShell {
  # Dependências de compilação C/Rust (essenciais para GTK e openssl-sys)
  packages = with pkgs; [
    # Bibliotecas GTK/Web/Criptografia (para compilação)
    at-spi2-atk
    atkmm
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    librsvg
    libsoup_3
    pango
    webkitgtk_4_1
    openssl

    # CORREÇÃO FINAL: Adicionar libxdo (resolve o erro '-lxdo')
    xdotool

    # O AJUSTE PRINCIPAL: Adicionar o wasm-bindgen
    wasm-bindgen-cli

    # Ferramentas de compilação
    pkg-config
    gcc
    rustup
    cargo
  ];

  shellHook = ''
    echo "Ambiente de desenvolvimento GTK/Rust carregado. Use 'cargo build' ou 'cargo install'."
  '';
}
