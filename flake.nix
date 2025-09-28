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
      # 🛠️ IMPORTAÇÃO DOS DEVSHELLS (Modularidade)
      # Nota: Esses arquivos (devShells/default.nix e devShells/python.nix) devem existir.
      # =================================================================
      devShellRust = import ./devShells/default.nix { inherit pkgs; };
      pythonDevShell = import ./devShells/python.nix { inherit pkgs; };

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
                # [REFINAMENTO]: Simplificado para permitir todos os pacotes unfree
                allowUnfree = true;
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
                  # [REFINAMENTO]: Uso de initExtra para comandos de inicialização,
                  # mantendo a carga de plugins e OMZsh/P10K mais declarativa.
                  initExtra = ''
                    # Source Oh My Zsh
                    export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
                    source $ZSH/oh-my-zsh.sh

                    # Source Powerlevel10k theme
                    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

                    # Load Powerlevel10k configuration if it exists
                    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

                    # Variáveis de Correção
                    export WEBKIT_DISABLE_DMABUF_RENDERER=1
                    export GDK_BACKEND="x11"
                  '';
                };

                # 1. Instalação: Habilita o Alacritty como um programa
                programs.alacritty = {
                  enable = true;
                  package = pkgs.alacritty; # Garante que está usando o pacote padrão

                  # 2. Configuração: Defina suas opções aqui.
                  settings = {
                    font = {
                      size = 12.0;
                      normal = {
                        family = "FiraCode Nerd Font";
                        style = "Regular";
                      };
                    };
                    window = {
                      dimensions = {
                        columns = 100;
                        lines = 30;
                      };
                      opacity = 0.9;
                    };
                    colors = {
                      primary = {
                        background = "0x1e1e2e";
                        foreground = "0xd9e0ee";
                      };
                    };
                    keyboard = {
                      bindings = [
                        {
                          key = "Return";
                          mods = "Control|Shift";
                          action = "SpawnNewInstance";
                        }
                      ];
                    };
                  };
                };

                home.packages = with pkgs; [
                  # ====================================================================
                  # 🐚 SHELL & PROMPT (ZSH)
                  # ====================================================================
                  rustup
                  zsh-powerlevel10k
                  zsh-autosuggestions
                  zsh-syntax-highlighting
                  oh-my-zsh

                  # ====================================================================
                  # 💻 EDITORES & AMBIENTES DE DESENVOLVIMENTO
                  # ====================================================================
                  vscodium
                  zed-editor
                  helix
                  jdk17_headless
                  android-studio
                  genymotion
                  lldb

                  # ====================================================================
                  # 🛠️ TOOLCHAINS & DEPENDÊNCIAS NATIVAS
                  # ====================================================================
                  gcc
                  openssl
                  pkg-config
                  dioxus-cli
                  nixfmt

                  # ====================================================================
                  # 🌐 LSPs & FORMATTERS
                  # ====================================================================
                  lua-language-server
                  python312Packages.python-lsp-server
                  pyright
                  black
                  stylua

                  # ====================================================================
                  # 🔡 FONTES
                  # ====================================================================
                  fira-code
                  jetbrains-mono
                  hack-font
                  nerd-fonts.fira-code
                  nerd-fonts.droid-sans-mono
                  meslo-lgs-nf
                ];

              };
          }
        ];
      };

      # =================================================================
      # 🚀 DEVSHELLS (Carregados a partir dos arquivos .nix)
      # =================================================================
      devShells.${system} = {
        default = devShellRust;
        rust = devShellRust;
        python = pythonDevShell;
      };
    };
}
