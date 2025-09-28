{
  description = "Configuração do NixOS de Marcelo com Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # =================================================================
      # 🛠️ AMBIENTE DE DESENVOLVIMENTO GTK/RUST (devShell Definição Original)
      # =================================================================
      devShellRust = pkgs.mkShell {
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

          # 🚀 CORREÇÃO FINAL: Adicionar libxdo (resolve o erro '-lxdo')
          xdotool # (xdotool geralmente inclui libxdo)

          # 🚀 O AJUSTE PRINCIPAL: Adicionar o wasm-bindgen
          wasm-bindgen-cli

          # Ferramentas de compilação
          pkg-config # Auxilia Rust a encontrar bibliotecas nativas
          gcc # Compilador C/C++
          rustup # Necessário para gerenciar toolchain Rust no devShell
          cargo
        ];

        shellHook = ''
          echo "Ambiente de desenvolvimento GTK/Rust carregado. Use 'cargo build' ou 'cargo install'."
        '';
      };

      # =================================================================
      # 🐍 AMBIENTE DE DESENVOLVIMENTO PYTHON/POETRY (NOVO devShell)
      # =================================================================
      pythonDevShell = pkgs.mkShell {
        # Define a versão do Python e o Poetry
        packages = with pkgs; [
          python312 # Versão específica do Python
          poetry

          # Ferramentas Python de qualidade de código (disponíveis na shell)
          black     # Formatador
          isort     # Ordenador de imports
          mypy      # Checador de tipo estático
          pylint    # Linter

          # Ferramenta para gestão de dependências nativas
          pkg-config
        ];

        shellHook = ''
          echo "Ambiente de desenvolvimento Python com Poetry carregado."
          echo "1. Use 'poetry install' para instalar as dependências do seu projeto."
          echo "2. Use 'poetry shell' para ativar o ambiente virtual do Poetry."
        '';
      };

    in
    {
      # =================================================================
      # 💻 NIXOS CONFIGURATIONS (Configuração do seu sistema)
      # =================================================================
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          # MÓDULO DE SISTEMA
          (
            { pkgs, ... }:
            {
              nixpkgs.config = {
                allowUnfree = true;
                allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "android-studio" ];
                android_sdk.accept_license = true;
              };

              services.flatpak.enable = true;

              environment.systemPackages = with pkgs; [
                flatpak
                xdg-desktop-portal
                kdePackages.xdg-desktop-portal-kde
                xdg-desktop-portal-gtk
                zsh
                oh-my-zsh
              ];

              programs.zsh.enable = true;

              users.users.marcelo = {
                isNormalUser = true;
                extraGroups = [
                  "wheel"
                  "networkmanager"
                ];
                shell = pkgs.zsh;
              };
            }
          )

          # MÓDULO HOME MANAGER
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.marcelo =
              { config, pkgs, ... }:
              {
                home.stateVersion = "25.05";
                fonts.fontconfig.enable = false;

                programs.zsh = {
                  enable = true;
                  oh-my-zsh = {
                    enable = true;
                    plugins = [ "git" ];
                  };
                  plugins = [
                    {
                      name = "zsh-autosuggestions";
                      src = pkgs.zsh-autosuggestions;
                      file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
                    }
                    {
                      name = "zsh-syntax-highlighting";
                      src = pkgs.zsh-syntax-highlighting;
                      file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
                    }
                  ];
                  initContent = ''
                    # Source Oh My Zsh
                    export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
                    source $ZSH/oh-my-zsh.sh

                    # Source Powerlevel10k theme
                    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

                    # Load Powerlevel10k configuration if it exists
                    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

                    # 🚀 CORREÇÃO NVIDIA/WEBKIT: Aplicado na sessão Zsh
                    export WEBKIT_DISABLE_DMABUF_RENDERER=1
                    export GDK_BACKEND="x11"
                  '';
                };

                # 1. Instalação: Habilita o Alacritty como um programa
                programs.alacritty = {
                  enable = true;
                  package = pkgs.alacritty; # Garante que está usando o pacote padrão

                  # 2. Configuração: Defina suas opções aqui.
                  # O Home Manager irá gerar o arquivo de configuração para você.
                  settings = {
                    # Configurações de Fontes (usando as Nerd Fonts que você instalou)
                    font = {
                      size = 12.0;
                      normal = {
                        # Use o nome da fonte exato no sistema (você pode verificar com `fc-list | grep Fira`)
                        family = "FiraCode Nerd Font";
                        style = "Regular";
                      };
                    };

                    # Configurações de Janela
                    window = {
                      dimensions = {
                        columns = 100;
                        lines = 30;
                      };
                      # Exemplo de Transparência (0.8 = 80% de opacidade)
                      opacity = 0.9;
                    };

                    # Cores - use um tema de sua preferência
                    # Exemplo de um tema simples (substitua pelos seus valores)
                    colors = {
                      primary = {
                        background = "0x1e1e2e";
                        foreground = "0xd9e0ee";
                      };
                      # ...outras configurações de cores (normal, bright, etc.)
                    };

                    # Keybindings (Atalhos de teclado)
                    keyboard = {
                      bindings = [
                        # Exemplo: Abrir uma nova instância na pasta atual (Ctrl+Shift+Enter)
                        {
                          key = "Return";
                          mods = "Control|Shift";
                          action = "SpawnNewInstance";
                        }
                      ];
                    };

                    # ...outras configurações (cursor, shell, etc.)
                  };
                };

                # 3. Certifique-se de que o fontconfig está habilitado para o Home Manager
                #fonts.fontconfig.enable = true;

                home.packages = with pkgs; [
                  # ====================================================================
                  # 🐚 SHELL & PROMPT (ZSH)
                  # ====================================================================

                  # Ferramenta principal para gerenciar toolchains Rust (compilador, cargo)
                  rustup

                  # Tema principal do Zsh (requer Nerd Font)
                  zsh-powerlevel10k

                  # Plugins Essenciais para Zsh
                  zsh-autosuggestions # Sugestões de comandos baseadas no histórico
                  zsh-syntax-highlighting # Colore comandos digitados para melhor legibilidade

                  # Framework opcional (pode ser removido se apenas os plugins acima forem usados)
                  oh-my-zsh

                  # ->
                  #alacritty

                  # ====================================================================
                  # 💻 EDITORES & AMBIENTES DE DESENVOLVIMENTO
                  # ====================================================================

                  # Editores de Código
                  vscodium
                  zed-editor
                  helix

                  # Plataformas & SDKs
                  jdk17_headless
                  android-studio
                  genymotion
                  lldb

                  # ====================================================================
                  # 🛠️ TOOLCHAINS & DEPENDÊNCIAS NATIVAS (Crucial para cargo/Rust)
                  # ====================================================================

                  # Compilador C/C++ (o rustup gerencia, mas mantemos o gcc para libs C)
                  gcc

                  # Bibliotecas C/C++ (OpenSSL, etc.)
                  openssl
                  pkg-config

                  # Pacotes Rust (Descomentar se não usar 'rustup')
                  # rustc
                  # cargo

                  # ✅ NOVO: Adicione o CLI do Dioxus (Instalação declarativa)
                  dioxus-cli
                  nixfmt

                  # ====================================================================
                  # 🌐 LSPs & FORMATTERS
                  # ====================================================================

                  # LSPs (Language Server Protocols)
                  lua-language-server
                  python312Packages.python-lsp-server
                  pyright

                  # Formatters & Linters
                  black
                  stylua

                  # ====================================================================
                  # 🔡 FONTES
                  # ====================================================================

                  # Fontes Monospace Padrão
                  fira-code
                  jetbrains-mono
                  hack-font

                  # Fontes Patcheadas (Nerd Fonts - Requerido para ícones do Powerlevel10k)
                  nerd-fonts.fira-code
                  nerd-fonts.droid-sans-mono
                  meslo-lgs-nf

                ];

              };
          }
        ];
      };

      # =================================================================
      # 🚀 DEVSHELLS (ADICIONADO AQUI, NÍVEL SUPERIOR)
      # =================================================================
      devShells.${system} = {
        # 'default' aponta para o ambiente Rust/GTK
        default = devShellRust;

        # 'rust' é um alias para o ambiente Rust/GTK
        rust = devShellRust;

        # 'python' aponta para o novo ambiente Python/Poetry
        python = pythonDevShell;
      };
    };
}
