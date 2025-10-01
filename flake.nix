{
  description = "Configuração do NixOS de Marcelo com Flakes (Migração para COSMIC)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # MANTIDO: nix4nvchad para o Neovim
    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix4nvchad,
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
          /etc/nixos/hardware-configuration.nix

          # System module (global packages and configurations)
          (
            { pkgs, ... }:
            {
              nixpkgs.config = {
                allowUnfree = true;
                android_sdk.accept_license = true;
              };

              nixpkgs.overlays = [ ];

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
                      { "neovim/nvim-lspconfig", lazy = false, },
                      {
                        "mrcjkb/rustaceanvim",
                        lazy = false,
                        config = function()
                          vim.g.rustaceanvim = { server = { cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" }, }, }
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
                            check = { command = "clippy", },
                            diagnostics = { enable = true, },
                            cargo = { allFeatures = true, },
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

                services.dunst.enable = true; # Opcional: Manter notificações no Home Manager, embora o COSMIC tenha as suas.

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
