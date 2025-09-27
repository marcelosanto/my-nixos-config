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

          # [CORRIGIDO] Lista ÚNICA de environment.systemPackages
          environment.systemPackages = with pkgs; [
            flatpak
            xdg-desktop-portal
            kdePackages.xdg-desktop-portal-kde
            xdg-desktop-portal-gtk
            zsh 
          ];
          
          # 🚀 CORREÇÃO DA ASSERÇÃO: Ativa o Zsh no nível do sistema
          programs.zsh.enable = true;

          # Configuração do Usuário Marcelo no Sistema
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
          
          # 🚀 SOLUÇÃO DE ESCOPO: Usa 'let' e 'builtins.toString' para resolver o caminho
          let
            p10k = builtins.toString pkgs.zsh-powerlevel10k;
            zshAutosuggestions = builtins.toString pkgs.zsh-autosuggestions;
            zshSyntaxHighlighting = builtins.toString pkgs.zsh-syntax-highlighting;
          in
          {
            home.stateVersion = "25.05";
            fonts.fontconfig.enable = false;
            
            # === CONFIGURAÇÃO DO ZSH E PLUGINS ===
            programs.zsh = {
              enable = true;
              # Deixa a lista de plugins vazia para evitar o erro de 'submodule'
              plugins = [ ]; 
              
              # Carregamento explícito usando as variáveis convertidas para string
              initExtra = ''
                # Carrega o plugin de Highlight
                source ${zshSyntaxHighlighting}/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
                
                # Carrega o plugin de Autosuggestions
                source ${zshAutosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
                
                # Carrega o Powerlevel10k
                if [[ -f ${p10k}/share/zsh-theme-powerlevel10k/powerlevel10k.zsh ]]; then
                    source ${p10k}/share/zsh-theme-powerlevel10k/powerlevel10k.zsh
                fi
              '';
            };
            
            # === PACOTES DE DESENVOLVIMENTO ===
            home.packages = with pkgs; [
              zsh-powerlevel10k # Continua na lista para ser instalado
              
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