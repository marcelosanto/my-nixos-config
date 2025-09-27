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
              zsh-powerlevel10k
              zsh-autosuggestions
              zsh-syntax-highlighting
              oh-my-zsh
              python3
              lua
              #rustc
              #cargo
              jdk17_headless
              android-studio
              vscodium
              zed-editor
              helix
              genymotion
              #rust-analyzer
              lldb
              fira-code
              jetbrains-mono
              hack-font
              lua-language-server
              python312Packages.python-lsp-server
              black
              pyright
              #rustfmt
              stylua
              rustup 
              gcc
            ];
          };
        }
      ];
    };
  };
}