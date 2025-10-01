{
  description = "Configuração do NixOS de Marcelo com Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix4nvchad,
      hyprland,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Import devShells for modular development environments
      devShellRust = import ./devShells/default.nix { inherit pkgs; };
      pythonDevShell = import ./devShells/python.nix { inherit pkgs; };
    in
    {
      # NixOS system configuration
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          ./configuration.nix
          # CORREÇÃO: Usar caminho relativo para evitar erro 'pure evaluation'
          /etc/nixos/hardware-configuration.nix

          # System module (global packages and configurations)
          (
            { pkgs, ... }:
            {
              nixpkgs.config = {
                allowUnfree = true;
                android_sdk.accept_license = true;
              };

              nixpkgs.overlays = [
                (final: prev: {
                  nvchad = inputs.nix4nvchad.packages.${system}.nvchad;
                  hyprland = inputs.hyprland.packages.${system}.hyprland;
                })
              ];

              services.flatpak.enable = true;

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
                extraGroups = [
                  "wheel"
                  "networkmanager"
                ];
                shell = pkgs.zsh;
              };
            }
          )

          # Home Manager module (user-specific configurations)
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.marcelo =
              {
                config,
                pkgs,
                inputs,
                ...
              }:
              {
                home.stateVersion = "25.05";
                fonts.fontconfig.enable = true;

                imports = [
                  inputs.nix4nvchad.homeManagerModules.nvchad
                ];

                # Módulo Hyprland
                wayland.windowManager.hyprland = {
                  enable = true;
                  package = pkgs.hyprland;
                  xwayland.enable = true;
                  extraConfig = ''
                    # Configuração básica do Hyprland
                    input {
                      kb_layout = br
                      kb_variant = abnt2
                      follow_mouse = 1
                      sensitivity = 0
                    }
                    general {
                      gaps_in = 5
                      gaps_out = 10
                      border_size = 2
                      col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
                      col.inactive_border = rgba(595959aa)
                    }
                    decoration {
                      rounding = 10
                      blur {
                        enabled = true
                        size = 3
                        passes = 1
                      }
                    }
                    animations {
                      enabled = true
                      bezier = myBezier, 0.05, 0.9, 0.1, 1.05
                      animation = windows, 1, 7, myBezier
                      animation = windowsOut, 1, 7, default, popin 80%
                      animation = border, 1, 10, default
                      animation = fade, 1, 7, default
                      animation = workspaces, 1, 6, default
                    }
                    $mainMod = SUPER
                    bind = $mainMod, Q, killactive,
                    bind = $mainMod, E, exec, alacritty
                    bind = $mainMod, C, exec, firefox
                    bind = $mainMod, M, exit,
                    bind = $mainMod, SPACE, exec, rofi -modi drun -show drun # Chamada Rofi com modo
                    bind = $mainMod, T, togglefloating,
                    bind = $mainMod, F, fullscreen,
                    # Movimentação entre workspaces
                    bind = $mainMod, 1, workspace, 1
                    bind = $mainMod, 2, workspace, 2
                    bind = $mainMod SHIFT, 1, movetoworkspace, 1
                    bind = $mainMod SHIFT, 2, movetoworkspace, 2
                    # Inicia Waybar, Hyprpaper e Dunst automaticamente
                    exec-once = waybar
                    exec-once = hyprpaper
                    exec-once = dunst
                  '';
                };

                # Configuração do Waybar
                programs.waybar = {
                  enable = true;
                  settings = {
                    mainBar = {
                      layer = "top";
                      position = "top";
                      modules-left = [
                        "hyprland/workspaces"
                        "hyprland/window"
                      ];
                      modules-center = [ ];
                      modules-right = [
                        "pulseaudio"
                        "network"
                        "cpu"
                        "memory"
                        "battery"
                        "clock"
                        "custom/theme"
                      ];
                      "hyprland/workspaces" = {
                        format = "{name}";
                        on-click = "activate";
                      };
                      "hyprland/window" = {
                        format = "{}";
                        max-length = 50;
                      };
                      pulseaudio = {
                        format = "{volume}% {icon}";
                        format-muted = "MUTED";
                        format-icons = {
                          default = [
                            "🔈"
                            "🔉"
                            "🔊"
                          ];
                        };
                        on-click = "pavucontrol";
                      };
                      network = {
                        format-wifi = "{essid} ({signalStrength}%) 📶";
                        format-ethernet = "Ethernet 🌐";
                        format-disconnected = "Disconnected ⚠";
                      };
                      cpu = {
                        format = "{usage}% 💻";
                      };
                      memory = {
                        format = "{}% 🧠";
                      };
                      battery = {
                        format = "{capacity}% {icon}";
                        format-icons = [
                          "🔋"
                          "🔌"
                        ];
                      };
                      clock = {
                        format = "{:%H:%M %d/%m/%Y}";
                      };
                      # Módulo de Tema
                      "custom/theme" = {
                        format = "🎨";
                        on-click = "~/.config/hypr/scripts/toggle-theme.sh";
                        tooltip = "true";
                        format-tooltip = "Alternar Tema (Requer Rebuild)";
                        exec-if = "${pkgs.bash}/bin/test -f ~/.config/hypr/scripts/toggle-theme.sh";
                      };
                    };
                  };
                  # ESTILO CSS PARA WAYBAR FLUTUANTE
                  style = ''
                    /* --- Configurações Globais (Incluindo Nerd Font com Fallback) --- */
                    * {
                      font-family: "FiraCode Nerd Font", "Fira Code", "Symbols Nerd Font", monospace;
                      font-size: 13px;
                      color: #d9e0ee;
                      transition: none;
                    }

                    /* --- Waybar Principal (Barra Flutuante) --- */
                    #waybar {
                      background: transparent;
                      margin: 10px 10px 0 10px;
                      border: none;
                      padding: 0;
                    }

                    /* --- Estilo dos Contêineres de Módulos (Os Blocos Arredondados) --- */
                    .modules-left,
                    .modules-right {
                      background-color: rgba(30, 30, 46, 0.9);
                      border-radius: 10px;
                      padding: 0 5px;
                    }

                    /* --- Estilo dos Workspaces --- */
                    #workspaces {
                        padding: 0;
                    }
                    #workspaces button {
                        padding: 0 8px;
                        color: #a6e3a1;
                        background: transparent;
                        box-shadow: none;
                        border: none;
                    }
                    #workspaces button:hover {
                        background: rgba(137, 180, 250, 0.2);
                    }
                    #workspaces button.focused {
                        color: #89b4fa;
                        border-bottom: 2px solid #89b4fa;
                        border-radius: 0;
                    }

                    /* --- Estilo do Módulo Janela (Para separar do Workspaces) --- */
                    #hyprland-window {
                        padding: 0 10px;
                        background-color: rgba(200, 200, 200, 0.1); 
                        margin: 0 5px;
                        border-radius: 8px;
                    }

                    #pulseaudio, 
                    #network, 
                    #cpu, 
                    #memory, 
                    #battery, 
                    #clock,
                    #custom-theme {
                      padding: 0 10px;
                      margin: 0;
                      border-left: 1px solid rgba(205, 214, 244, 0.1);
                    }

                    /* Remove a linha divisória do primeiro módulo à direita */
                    #pulseaudio {
                        border-left: none; 
                    }

                    /* Remove o background do centro se não estiver em uso */
                    .modules-center {
                        background: transparent;
                    }
                  '';
                };

                # Script para Alternar Temas (A Waybar executa isso)
                home.file.".config/hypr/scripts/toggle-theme.sh" = {
                  executable = true;
                  text = ''
                    #!/usr/bin/env bash

                    # Arquivo de estado para rastrear o tema atual (dark ou light)
                    THEME_STATE_FILE="$HOME/.config/hypr/theme_state.txt"

                    # Alterna o estado (dark <-> light)
                    if [ ! -f "$THEME_STATE_FILE" ] || [ "$(cat "$THEME_STATE_FILE")" = "light" ]; then
                        echo "dark" > "$THEME_STATE_FILE"
                        NEW_THEME="Dark"
                    else
                        echo "light" > "$THEME_STATE_FILE"
                        NEW_THEME="Light"
                    fi

                    # Notifica o usuário e sugere a reconstrução
                    ${pkgs.dunst}/bin/dunstify "✨ Tema Alterado para $NEW_THEME!" "Execute 'sudo nixos-rebuild switch --flake .#nixos' (em /etc/nixos) para aplicar o novo esquema de cores." -t 10000
                  '';
                };

                # Configuração do Hyprpaper
                home.file.".config/hypr/hyprpaper.conf".text = ''
                  preload = /home/marcelo/wallpapers/meu-wallpaper.jpg
                  wallpaper = ,/home/marcelo/wallpapers/meu-wallpaper.jpg
                  splash = false
                '';

                # CONFIGURAÇÃO DE TEMA ROFI (COMPACTO E ARREDONDADO)
                programs.rofi = {
                  enable = true;
                  theme = {
                    "*" = {
                      font = "FiraCode Nerd Font 10";
                      background-color = "rgba(30, 30, 46, 0.95)";
                      text-color = "#cdd6f4";
                      border-color = "#89b4fa";

                      # Estilo da Janela
                      border = 0;
                      border-radius = 20; # Cantos mais arredondados
                      padding = 0;
                      width = 300; # Largura reduzida
                    };
                    "window" = {
                      location = 0;
                      anchor = 0;
                      padding = 15; # Padding maior na janela para afastar
                    };
                    "inputbar" = {
                      children = [
                        "prompt"
                        "entry"
                      ];
                      spacing = 10;
                      padding = 10;
                      border-radius = 15;
                      background-color = "#45475a";
                    };
                    "listview" = {
                      columns = 1;
                      lines = 7; # Limita as linhas
                      spacing = 5;
                      cycle = false;
                      dynamic = true;
                      scrollbar = false;
                      padding = 5;
                    };
                    "element" = {
                      padding = 10;
                      spacing = 10;
                      border-radius = 12;
                      background-color = "transparent";
                    };
                    "element selected" = {
                      background-color = "#89b4fa";
                      text-color = "#1e1e2e";
                      border-radius = 12;
                    };
                    "entry" = {
                      placeholder = "Pesquisar Aplicativos...";
                    };
                  };
                };

                programs.nvchad = {
                  enable = true;
                  extraPackages = with pkgs; [
                    rust-analyzer
                    lua-language-server
                    pyright
                    black
                    stylua
                    nil
                    rustfmt
                    python312Packages.flake8
                    cargo
                  ];
                  extraPlugins = ''
                    return {
                      {
                        "neovim/nvim-lspconfig",
                        lazy = false,
                      },
                      {
                        "mrcjkb/rustaceanvim",
                        lazy = false,
                        config = function()
                          vim.g.rustaceanvim = {
                            server = {
                              cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" },
                            },
                          }
                        end,
                      },
                      {
                        "mfussenegger/nvim-dap-python",
                        dependencies = { "mfussenegger/nvim-dap" },
                        config = function()
                          require("dap-python").setup("${pkgs.python3}/bin/python")
                        end,
                      },
                      {
                        "folke/neodev.nvim",
                        config = function()
                          require("neodev").setup({})
                        end,
                      },
                    }
                  '';
                  extraConfig = ''
                    local lspconfig_ok, lspconfig = pcall(require, 'lspconfig')
                    if not lspconfig_ok then
                      vim.notify("Erro: nvim-lspconfig não está disponível", vim.log.levels.ERROR)
                      return
                    end
                    vim.g.rustaceanvim = {
                      server = {
                        cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" },
                        settings = {
                          ["rust-analyzer"] = {
                            check = {
                              command = "clippy",
                            },
                            diagnostics = {
                              enable = true,
                            },
                            cargo = {
                              allFeatures = true,
                            },
                          },
                        },
                      },
                    }
                    vim.lsp.config.lua_ls.setup {
                      cmd = { "${pkgs.lua-language-server}/bin/lua-language-server" },
                      settings = {
                        Lua = {
                          runtime = { version = "LuaJIT" },
                          diagnostics = { globals = { "vim" } },
                          workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                          telemetry = { enable = false },
                        },
                      },
                    }
                    vim.lsp.config.pyright.setup {
                      cmd = { "${pkgs.pyright}/bin/pyright-langserver", "--stdio" },
                      settings = {
                        python = {
                          analysis = {
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                            diagnosticMode = "workspace",
                          },
                        },
                      },
                    }
                    vim.api.nvim_create_autocmd("BufWritePre", {
                      pattern = { "*.rs" },
                      callback = function() vim.lsp.buf.format { async = false } end,
                    })
                    vim.api.nvim_create_autocmd("BufWritePre", {
                      pattern = { "*.lua" },
                      callback = function() vim.lsp.buf.format { async = false } end,
                    })
                    vim.api.nvim_create_autocmd("BufWritePre", {
                      pattern = { "*.py" },
                      callback = function() vim.lsp.buf.format { async = false } end,
                    })
                    vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
                    vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { desc = "Go to References" })
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol" })
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
                  '';
                  hm-activation = true;
                  backup = true;
                };

                programs.zsh = {
                  enable = true;
                  oh-my-zsh = {
                    enable = true;
                    plugins = [ "git" ];
                  };
                  plugins = [
                    {
                      name = "powerlevel10k";
                      src = pkgs.zsh-powerlevel10k;
                      file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
                    }
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
                    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
                    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

                    export WEBKIT_DISABLE_DMABUF_RENDERER=1
                    export GDK_BACKEND="x11"
                    export LC_ALL="C.UTF-8"
                  '';
                };

                programs.alacritty = {
                  enable = true;
                  package = pkgs.alacritty;
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
                    mouse = {
                      bindings = [
                        {
                          mouse = "Right";
                          action = "Paste";
                          mods = "None";
                        }
                      ];
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

                programs.tmux = {
                  enable = true;
                  keyMode = "vi";
                  mouse = true;
                  prefix = "C-a";
                  terminal = "screen-256color";
                  extraConfig = ''
                    bind c new-window -c "#{pane_current_path}"
                  '';
                };

                services.dunst.enable = true;

                home.packages = with pkgs; [
                  rustup
                  tmux
                  vscodium
                  zed-editor
                  helix
                  jdk17_headless
                  android-studio
                  android-tools
                  genymotion
                  lldb
                  gcc
                  openssl
                  pkg-config
                  dioxus-cli
                  nixfmt
                  fira-code
                  jetbrains-mono
                  hack-font
                  nerd-fonts.fira-code
                  nerd-fonts.droid-sans-mono
                  noto-fonts-emoji
                  meslo-lgs-nf
                  discord
                  telegram-desktop
                  hyprpaper
                  hyprcursor
                  rofi
                ];
              };
          }
        ];
      };

      devShells.${system} = {
        default = devShellRust;
        rust = devShellRust;
        python = pythonDevShell;
      };
    };
}
