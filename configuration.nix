{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # A importação do hardware-configuration.nix é feita via flake.nix
    # para que possa ser mantida fora do Git.
  ];

  # ====================================================================
  # CONFIGURAÇÃO DE HARDWARE E SISTEMA DE ARQUIVOS
  # ====================================================================

  # --- Automaontagem de Disco NTFS (CORREÇÃO DE CONFLITO) ---
  fileSystems."/mnt/GAMES" = {
    # O valor do device está em conflito, forçamos o nosso valor
    device = lib.mkForce "UUID=2DBB801B3AC731E7";
    fsType = "ntfs3";

    # Forçamos a nossa lista de options para garantir que o uid/gid sejam usados
    options = lib.mkForce [
      "defaults"
      "nofail"
      "uid=1000"
      "gid=100"
      "umask=002"
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

  # Ativa o Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland; # Usa a versão do overlay (Hyprland mais recente)
  };

  # Ativa o SDDM com suporte a Wayland
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Desativa o Plasma 6 (descomente se quiser manter ambas as sessões)
  # services.desktopManager.plasma6.enable = true;

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

  # Garante que o Qt encontre o suporte ao PipeWire (resolve o aviso no Kate)
  environment.sessionVariables = {
    QT_PIPEWIRE_SUPPORT = "1";
    NIXOS_OZONE_WL = "1"; # Para apps Electron usarem Wayland
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

  # Configuração do Usuário
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

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "marcelo";

  # ====================================================================
  # PACOTES GLOBAIS E FLAKES
  # ====================================================================

  programs.firefox.enable = true;
  programs.adb.enable = true;

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
    # Adicionado qt6.qtmultimedia para compatibilidade com Plasma 6 e Kate
    qt6.qtmultimedia
    # Pacotes recomendados para Hyprland
    waybar
    rofi
    wl-clipboard
    grim
    slurp
    xdg-desktop-portal-hyprland
  ];

  # Outros serviços
  services.printing.enable = true;

  system.stateVersion = "25.05";
}
