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

          # Adicionar o Flatpak aos pacotes do sistema
          environment.systemPackages = with pkgs; [
            flatpak
            xdg-desktop-portal
            kdePackages.xdg-desktop-portal-kde
            xdg-desktop-portal-gtk # Para melhor integração com ambientes gráficos
          ];

         

        })


        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.marcelo = { pkgs, ... }: {
            home.stateVersion = "25.05";
            fonts.fontconfig.enable = false; # Disable fontconfig to avoid potential issues

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
              fira-code
              jetbrains-mono
              hack-font
              lua-language-server
              nerd-fonts.fira-code
              nerd-fonts.droid-sans-mono
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
