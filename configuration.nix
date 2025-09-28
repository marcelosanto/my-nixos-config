{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan (imported via flake.nix)
    #./hardware-configuration.nix
  ];

  # ====================================================================
  # CONFIGURAÇÃO DE HARDWARE E SISTEMA DE ARQUIVOS
  # ====================================================================

  # Criação do ponto de montagem com permissões corretas antes da montagem
  systemd.tmpfiles.rules = [
    "d /mnt/GAMES 0775 marcelo users -"
  ];

  # Bootloader
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

  # Ensure Qt applications use PipeWire
  environment.sessionVariables = {
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

  # Lista de systemPackages
  environment.systemPackages = with pkgs; [
    wget
    git
    zsh
    gcc
    qt6.qtmultimedia # Use Qt6 for Plasma 6 compatibility
  ];

  # Outros serviços
  services.printing.enable = true;

  system.stateVersion = "25.05";
}
