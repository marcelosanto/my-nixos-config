{
  description = "Configuração do NixOS de Marcelo com Flakes";

  inputs = {
    # Nixpkgs (pacotes principais)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Home Manager (para configurações do usuário)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        # Arquivos essenciais do sistema
        ./configuration.nix
        ./hardware-configuration.nix

        # MÓDULO DE SISTEMA (Flatpak, Unfree, Pacotes Globais)
        ({ pkgs, ... }: {
          nixpkgs.config = {
            allowUnfree = true;
            allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "android-studio"
            ];
            android_sdk.accept_license = true;
          };

          # Habilitar o Flatpak
          services.flatpak.enable = true;
          environment.systemPackages = with pkgs; [
            flatpak
            xdg-desktop-portal
            kdePackages.xdg-desktop-portal-kde
            xdg-desktop-portal-gtk
          ];
          
          # [ADICIONADO] Garante que o Zsh esteja no sistema
          environment.systemPackages = [ pkgs.zsh ];

          # [OPCIONAL] Define o shell padrão do usuário no sistema
          users.users.marcelo.shell = pkgs.zsh;
        })

        # MÓDULO HOME MANAGER
        # 1. Importação Simples do Módulo Home Manager
        home-manager.nixosModules.home-manager
        
        # 2. Configurações Globais e de Usuário do Home Manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          
          # Configurações Específicas para o usuário 'marcelo'
          home-manager.users.marcelo = { pkgs, ... }: {
            home.stateVersion = "25.05";
            fonts.fontconfig.enable = false;
            
            # === CONFIGURAÇÃO DO ZSH E POWERLEVEL10K (CORRIGIDA) ===
            programs.zsh = {
              enable = true;
              
              plugins = [
                { name = "zsh-autosuggestions"; package = pkgs.zsh-autosuggestions; }
                { name = "zsh-syntax-highlighting"; package = pkgs.zsh-syntax-highlighting; }
                "git"
              ];
            };

            # Powerlevel10k (Chave de programa de nível superior)
            programs.powerlevel10k.enable = true;
            
            # === PACOTES DE DESENVOLVIMENTO (home.packages) ===
            home.packages = with pkgs; [
              python3
              lua
              rustc
              cargo
              jdk17_headless
              android-studio
              vscodium
              zed-editor
              helix
              genymotion
              rust-analyzer
              lldb
              
              # Fontes
              fira-code
              jetbrains-mono
              hack-font
              nerd-fonts.fira-code
              nerd-fonts.droid-sans-mono
              
              # LSPs e Formatadores
              lua-language-server
              python312Packages.python-lsp-server
              black # Formatter de Python
              pyright
              rustfmt
              stylua
            ];
          };
        }
      ];
    };
  };
}