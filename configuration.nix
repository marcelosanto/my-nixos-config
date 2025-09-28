# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # ====================================================================
  # CONFIGURAÇÃO DE HARDWARE E SISTEMA DE ARQUIVOS
  # ====================================================================

  # --- Automaontagem de Disco NTFS ---
  # UUID do HD de Jogos: 2DBB801B3AC731E7 (NTFS)
  fileSystems."/mnt/GAMES" = {
    device = "UUID=2DBB801B3AC731E7";
    fsType = "ntfs3"; # Usando o driver moderno ntfs3

    # Permissões totais para o usuário marcelo (assumindo UID=1000, GID=100)
    options = [
      "defaults"
      "nofail"
      "uid=1000" # Substitua pelo seu UID real (id -u marcelo)
      "gid=100" # Substitua pelo seu GID real (id -g marcelo)
      "umask=002" # Permite r/w para dono e grupo
    ];
  };

  # Criação do ponto de montagem com permissões corretas antes da montagem
  systemd.tmpfiles.rules = [
    "d /mnt/GAMES 0775 marcelo users -"
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.loader.grub.useOSProber = true;

  # ====================================================================
  # CONFIGURAÇÃO DE REDE, LOCALIZAÇÃO E DISPLAY
  # ====================================================================

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
  ];

  networking.networkmanager.dns = "none";
  services.resolved.enable = false;

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  console.keyMap = "br-abnt2";

  # ====================================================================
  # GRÁFICOS, ÁUDIO E USUÁRIO
  # ====================================================================

  # Áudio Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ✅ CORREÇÃO: Adicionar pacotes de suporte ao PipeWire para o ambiente Qt/KDE
  environment.sessionVariables = {
    # Garante que o Qt está procurando o backend PipeWire
    QT_PIPEWIRE_SUPPORT = "1";
  };

  # Configuração NVIDIA
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
  };

  programs.nix-ld.enable = true;

  # Configuração do Usuário
  users.users.marcelo = {
    isNormalUser = true;
    description = "Marcelo Santos";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    # Mantenha o Kate aqui, mas garanta que ele use os pacotes KDE corretos.
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "marcelo";

  # ====================================================================
  # PACOTES GLOBAIS E FLAKES
  # ====================================================================

  programs.firefox.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Lista CORRIGIDA de systemPackages: SÓ FERRAMENTAS GLOBAIS
  environment.systemPackages = with pkgs; [
    wget
    git
    zsh
    gcc

    # ✅ NOVO: Adiciona o plugin de multimídia do Qt5 com PipeWire (necessário para a maioria das libs Qt)
    # Se você notar que o erro ainda aparece, tente descomentar a linha qt6 abaixo.
    qt5.qtmultimedia.withPipeWire
    # qt6.qtmultimedia.withPipeWire # Alternativa se o Kate estiver usando Qt6
  ];

  # Outros serviços
  services.printing.enable = true;

  system.stateVersion = "25.05";
}
