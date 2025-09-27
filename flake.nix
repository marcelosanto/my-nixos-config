{
  description = "Configuração do NixOS de Marcelo com Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix
        ./hardware-configuration.nix

        # MÓDULO DE SISTEMA
        ({ pkgs, ... }: {
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
            extraGroups = [ "wheel" "networkmanager" ];
            shell = pkgs.zsh;
          };
        })

        # MÓDULO HOME MANAGER
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.marcelo = { config, pkgs, ... }: {
            home.stateVersion = "25.05";
            fonts.fontconfig.enable = false;

            programs.zsh = {
              enable = true;
              oh-my-zsh = {
                enable = true;
                plugins = [ "git" ];
                # Do not set theme here; we'll source Powerlevel10k manually
                # theme = "powerlevel10k/powerlevel10k";
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
              '';
            };

            home.packages = with pkgs; [
              # ====================================================================
              # 🐚 SHELL & PROMPT (ZSH)
              # ====================================================================
              
              # Ferramenta principal para gerenciar toolchains Rust (compilador, cargo)
              rustup
              
              # Tema principal do Zsh (requer Nerd Font)
              zsh-powerlevel10k
              
              # Plugins Essenciais para Zsh
              zsh-autosuggestions        # Sugestões de comandos baseadas no histórico
              zsh-syntax-highlighting    # Colore comandos digitados para melhor legibilidade
              
              # Framework opcional (pode ser removido se apenas os plugins acima forem usados)
              oh-my-zsh                  
              
              # ====================================================================
              # 💻 EDITORES & AMBIENTES DE DESENVOLVIMENTO
              # ====================================================================
              
              # Editores de Código
              vscodium                   # Editor VS Code (Open Source)
              zed-editor                 # Editor Moderno (opcional, requer compilação específica)
              helix                      # Editor de Terminal Modal
              
              # Plataformas & SDKs
              jdk17_headless             # Kit de desenvolvimento Java (para Android Studio, sem UI)
              android-studio             # IDE principal para desenvolvimento Android
              genymotion                 # Emulador Android (para testes)
              lldb                       # Debugger de baixo nível (necessário para Rust/C/C++)
              
              # ====================================================================
              # 🛠️ TOOLCHAINS & DEPENDÊNCIAS NATIVAS (Crucial para cargo/Rust)
              # ====================================================================
              
              # Compilador C/C++ (Necessário para a compilação de muitas libs nativas Rust)
              gcc
              
              # Bibliotecas C/C++ (Soluciona erros comuns como 'openssl-sys')
              openssl                    # Biblioteca criptográfica (OpenSSL)
              pkg-config                 # Auxilia compiladores a encontrar flags e bibliotecas nativas
              
              # Pacotes Rust (Descomentar se não usar 'rustup' para instalar)
              # rustc
              # cargo
              
              # ====================================================================
              # 🌐 LSPs & FORMATTERS (Para Helix, VSCodium, Zed)
              # ====================================================================
              
              # LSPs (Language Server Protocols)
              lua-language-server        # LSP para a linguagem Lua
              python312Packages.python-lsp-server # LSP para a linguagem Python (base)
              pyright                    # LSP mais avançado para Python (Microsoft)
              # rust-analyzer            # LSP para a linguagem Rust (Gerenciado por rustup ou instalado separadamente)

              # Formatters & Linters
              black                      # Formatador de código Python (muito popular)
              stylua                     # Formatador de código Lua
              # rustfmt                  # Formatador de código Rust (Gerenciado por rustup ou instalado separadamente)
              
              # ====================================================================
              # 🔡 FONTES (Crucial para Powerlevel10k)
              # ====================================================================
              
              # Fontes Monospace Padrão
              fira-code
              jetbrains-mono
              hack-font

              # Fontes Patcheadas (Nerd Fonts - Requerido para ícones do Powerlevel10k)
              nerd-fonts.fira-code
              nerd-fonts.droid-sans-mono
            ];
            
          };
        }
      ];
    };
  };
}