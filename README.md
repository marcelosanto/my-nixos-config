# 💻 NixOS Flake Configuration - Marcelo (x86_64-linux)

Esta é a minha configuração declarativa do sistema NixOS e Home Manager, gerenciada com Flakes. O objetivo é fornecer um ambiente de desenvolvimento robusto para projetos **Rust**, **GTK** e **Python**, isolando dependências através dos `devShells`.

## ⚙️ Estrutura do Repositório

O repositório está organizado de forma modular, com o `flake.nix` orquestrando o sistema e o ambiente de usuário.


```

.

├── devShells/

│ ├── default.nix # Ambiente de desenvolvimento Rust/GTK

│ └── python.nix # Ambiente de desenvolvimento Python/Poetry

├── configuration.nix

├── hardware-configuration.nix

└── flake.nix

```

## 🚀 Como Usar/Reconstruir

### 1. Reconstruir o Sistema

Para aplicar as mudanças no seu sistema NixOS, use o comando:

```bash
sudo nixos-rebuild switch --flake .#nixos

```

### 2. Ambientes de Desenvolvimento (DevShells)

O Flake define ambientes isolados para diferentes tipos de projeto. Para entrar em um ambiente específico, use o comando `nix develop`:

Ambiente

Comando para Carregar

Descrição

**Rust/GTK** (Padrão)

`nix develop` ou `nix develop .#rust`

Contém `rustup`, `cargo`, `gcc`, `pkg-config`, e bibliotecas GTK.

**Python/Poetry**

`nix develop .#python`

Contém `python312`, `poetry`, `black`, `mypy` e ferramentas de qualidade de código.

#### Fluxo de Trabalho Python/Poetry:

1.  Entre na shell: `nix develop .#python`
    
2.  Dentro da shell, use o `poetry` para gerenciar seu projeto:
    
    -   `poetry install` (Instala as dependências)
        
    -   `poetry shell` (Ativa o ambiente virtual)
        

## ✨ Destaques da Configuração

-   **Gerenciamento de Shell:** Zsh com **Oh My Zsh**, tema **Powerlevel10k**, e plugins essenciais (`zsh-autosuggestions`, `zsh-syntax-highlighting`).
    
-   **Terminal:** Configuração completa do **Alacritty** (incluindo fontes Nerd Fonts e cores).
    
-   **IDEs & Editores:** Instalação de **VSCodium**, **Zed Editor** e **Helix**.
    
-   **Desenvolvimento Mobile:** Suporte para **Android Studio** e **Genymotion** (pacotes unfree habilitados).
    
-   **Ferramentas de Qualidade:** LSPs (`python-lsp-server`, `pyright`, `lua-language-server`) e formatters (`black`, `stylua`) disponíveis globalmente para o usuário.
