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
        ./configuration.nix
        ./hardware-configuration.nix

        # MÓDULO DE SISTEMA (Configurações Globais)
        ({ pkgs, ... }: {
          
          nixpkgs.config = {
            allowUnfree = true;
            allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "android-studio" ];
            android_sdk.accept_license = true;
          };

          services.flatpak.enable = true;

          # Lista ÚNICA de environment.systemPackages
          environment.systemPackages = with pkgs; [
            flatpak
            xdg-desktop-portal
            kdePackages.xdg-desktop-portal-kde
            xdg-desktop-portal-gtk
            zsh 
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
        
        # Configurações Globais e de Usuário do Home Manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          
          # Configurações Específicas para o usuário 'marcelo'
          home-manager.users.marcelo = { config, pkgs, ... }: 
          {
            home.stateVersion = "25.05";
            fonts.fontconfig.enable = false;
            
            # === CONFIGURAÇÃO DO ZSH E PLUGINS ===
            programs.zsh = {
              enable = true;
              
              # ✅ CORREÇÃO: Usa a lista de plugins do Home Manager.
              # O Home Manager cuidará da instalação e do 'sourcing' correto.
              plugins = [ 
                { name = "zsh-autosuggestions"; package = pkgs.zsh-autosuggestions; }
                { name = "zsh-syntax-highlighting"; package = pkgs.zsh-syntax-highlighting; }
              ];
              
              # Apenas para garantir que o Home Manager não exclua nada
              initContent = ""; 
            };
            
            # ✅ CORREÇÃO: Usa o módulo dedicado do Powerlevel10k
            programs.powerlevel10k.enable = true;
            
            # === PACOTES DE DESENVOLVIMENTO ===
            # Removido zsh-powerlevel10k, zsh-autosuggestions e zsh-syntax-highlighting desta lista,
            # pois eles serão instalados pelos módulos programs.zsh e programs.powerlevel10k.
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
              black 
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