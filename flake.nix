{
  description = "Configuração do NixOS de Marcelo com Flakes";

  inputs = {
    # Nixpkgs (pacotes principais)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Home Manager (para configurações do usuário)
    home-manager.url = "github:nix-community/home-manager";
    # Garante que o Home Manager use o mesmo conjunto de pacotes que o sistema
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # Define a configuração do sistema (seu único host 'nixos')
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        # Arquivos essenciais do sistema
        ./configuration.nix
        ./hardware-configuration.nix

        # Módulo de sistema para pacotes, flatpak, etc.
        ({ pkgs, ... }: {
          nixpkgs.config = {
            allowUnfree = true;
            # Permite apenas o android-studio, mantendo outros pacotes restritos
            allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "android-studio"
            ];
            android_sdk.accept_license = true;
          };

          # Habilitar o Flatpak
          services.flatpak.enable = true;

          # Adicionar o Flatpak aos pacotes do sistema
          environment.systemPackages = with pkgs; [
            flatpak
            xdg-desktop-portal
            kdePackages.xdg-desktop-portal-kde
            xdg-desktop-portal-gtk
          ];
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
            # Desabilitar o fontconfig é incomum, mas mantido conforme seu pedido
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

            # Powerlevel10k é um módulo de programa de nível superior
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