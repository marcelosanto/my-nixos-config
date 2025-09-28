{ pkgs }:

pkgs.mkShell {
  # Define a versão do Python e o Poetry
  packages = with pkgs; [
    python312 # Versão específica do Python
    poetry

    # Ferramentas Python de qualidade de código (disponíveis na shell)
    black     # Formatador
    isort     # Ordenador de imports
    mypy      # Checador de tipo estático
    pylint    # Linter

    # Ferramenta para gestão de dependências nativas
    pkg-config
  ];

  shellHook = ''
    echo "Ambiente de desenvolvimento Python com Poetry carregado."
    echo "1. Use 'poetry install' para instalar as dependências do seu projeto."
    echo "2. Use 'poetry shell' para ativar o ambiente virtual do Poetry."
  '';
}
