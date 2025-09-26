{
  description = "Configuração do NixOS de Marcelo com Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # Adjust if your architecture differs

      modules = [
        # Your existing configuration files
        ./configuration.nix
        ./hardware-configuration.nix

        # Allow unfree packages at the system level
        {
          nixpkgs.config.allowUnfree = true;
        }

        # Home Manager configuration
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true; # Use the same pkgs as the system
          home-manager.users.marcelo = {
            home.stateVersion = "24.05"; # Match your NixOS version

            # User-specific packages
            home.packages = with nixpkgs.legacyPackages.x86_64-linux; [
              python3
              lua
              rustc
              cargo
              jdk17_headless # Java Development Kit 17 (headless for Gradle)
              android-studio # IDE Android Studio
              vscodium      # Codium (free version of VS Code)
              zed-editor    # Zed IDE
              helix         # Helix Editor (hx)
            ];

            # Optionally enable nix-ld for non-Nix binaries
            programs.nix-ld.enable = true;
          };
        }
      ];
    };
  };
}
