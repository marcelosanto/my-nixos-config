{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # A importação do hardware-configuration.nix é feita via flake.nix
  ];

  # ====================================================================
  # CONFIGURAÇÃO DE HARDWARE E SISTEMA DE ARQUIVOS
  # ====================================================================

  fileSystems."/mnt/GAMES" = {
    device = lib.mkForce "UUID=2DBB801B3AC731E7";
    fsType = "ntfs3";
    options = lib.mkForce [
      "defaults"
      "nofail"
      "uid=1000"
      "gid=100"
      "umask=002"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/GAMES 0775 marcelo users -"
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  # SINTAXE CORRIGIDA: Usa 'devices' (lista)
  boot.loader.grub.devices = [ "/dev/sdb" ];
  boot.loader.grub.useOSProber = true;

  # ====================================================================
  # CONFIGURAÇÃO DE REDE, LOCALIZAÇÃO E DISPLAY
  # ====================================================================

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
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

  # ====================================================================
  # AMBIENTE DE TRABALHO: COSMIC
  # ====================================================================

  # --- DESABILITA HYPRLAND ---
  programs.hyprland.enable = lib.mkForce false;

  # --- DESABILITA SDDM ---
  services.displayManager.sddm.enable = false;

  # --- HABILITA COSMIC ---
  services.xserver.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "marcelo";

  # Variáveis de sessão para Wayland/COSMIC
  environment.sessionVariables = {
    QT_PIPEWIRE_SUPPORT = "1";
    NIXOS_OZONE_WL = "1";
    COSMIC_DATA_CONTROL_ENABLED = "1";
  };

  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  console.keyMap = "br-abnt2";

  # ====================================================================
  # GRÁFICOS E ÁUDIO
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

  # Configuração NVIDIA
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  programs.nix-ld.enable = true;

  # ====================================================================
  # USUÁRIO E PACOTES GLOBAIS
  # ====================================================================

  programs.firefox.enable = true;
  programs.adb.enable = true;

  users.users.marcelo = {
    isNormalUser = true;
    description = "Marcelo Santos";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    zsh
    gcc
    qt6.qtmultimedia
  ];

  # Outros serviços
  services.printing.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
