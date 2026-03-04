{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.otakuracer = import ./home.nix;
  };

  # System Settings
  nixpkgs.config.allowUnfree = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-x450jf";
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  time.timeZone = "Asia/Jakarta";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # GPU Force Intel - blacklist Nvidia
  services.thermald.enable = true;
  services.xserver.enable = false;
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];
  boot.kernelParams = [ "module_blacklist=nouveau,nvidia" "video=eDp-1:d" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "i965";
  };

  # TUI Login
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri";
        user = "greeter";
      };
    };
  };

  # Essential for Wayland Portals (used by niri)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.niri.enable = true;
  programs.xwayland.enable = true;
  services.flatpak.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  services.gvfs.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Automatically add Flathub remote system activation
  system.activationScripts.flatpakRemote = {
    text = ''
      if ${pkgs.flatpak}/bin/flatpak remote-list --system | grep -q "flathub"; then
        echo "Flathub remote already exists, skipping."
      else
        ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub \
          https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    '';
    deps = [];
  };

  # ZRAM and SWAP
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
  swapDevices = [
    { device = "/swapfile"; }
  ];

  boot.kernel.sysctl = { "vm.swappiness" = 60; };

  programs.nix-ld.enable = true;

  users.users.otakuracer = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  };

  # Package List
  environment.systemPackages = with pkgs; [
    (vim-full.customize {
      name = "vim";
      vimrcConfig.customRC = ''
        filetype plugin indent on
        set expandtab
        set shiftwidth=4
        set softtabstop=4
        set tabstop=4
        set number
        set relativenumber
        set smartindent
        set showmatch
        set backspace=indent,eol,start
        syntax on
        set mouse=a
      '';
    })
    alacritty
    git
    firefox
    rofi
    pavucontrol
    btop
    libsecret
    feishin
    featherpad
    glmark2
    greetd
    ghostty
    onlyoffice-desktopeditors
    kdePackages.dolphin
    kdePackages.ark
    xwayland-satellite
    wlr-randr
    waybar
 ];

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  # System-wide Ark default (all users)
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    application/zip=org.kde.ark.desktop
    application/x-tar=org.kde.ark.desktop
    application/x-bzip2=org.kde.ark.desktop
    application/x-gzip=org.kde.ark.desktop
    application/x-7z-compressed=org.kde.ark.desktop
    application/x-xz=org.kde.ark.desktop
    application/x-rar=org.kde.ark.desktop
    application/x-arj=org.kde.ark.desktop
    application/x-cab=org.kde.ark.desktop
    application/x-lzip=org.kde.ark.desktop
    application/x-iso9660-image=org.kde.ark.desktop
    application/x-rpm=org.kde.ark.desktop
  '';

  system.stateVersion = "25.11";
}
