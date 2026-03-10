{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Nix Settings ────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Bootloader ───────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # ── Kernel & GPU (Force Intel, blacklist Nvidia) ─────────────────────────────
  services.thermald.enable = true;
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];
  boot.kernelParams = [ "module_blacklist=nouveau,nvidia" "video=eDp-1:d" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # ── ZRAM & Swap (laptop needs swapfile) ──────────────────────────────────────
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  swapDevices = [
    { device = "/swapfile"; }
  ];

  # ── Storage ──────────────────────────────────────────────────────────────────
  fileSystems."/data" = {
    device = "/dev/disk/by-label/storage";
    fsType = "ext4";
    options = [ "defaults" "x-gvfs-show" ];
  };

  boot.kernel.sysctl = {
    "vm.swappiness"         = 100;
    "vm.vfs_cache_pressure" = 50;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  # ── Networking ───────────────────────────────────────────────────────────────
  networking.hostName = "nixos-x450jf";
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  # ── Locale & Time ────────────────────────────────────────────────────────────
  time.timeZone = "Asia/Jakarta";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Session Variables ────────────────────────────────────────────────────────
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME                 = "i965";
    GTK_THEME                         = "catppuccin-mocha-standard-blue-dark";
    GTK_APPLICATION_PREFER_DARK_THEME = "1";
    QT_QPA_PLATFORMTHEME              = "qt6ct";
    QT_AUTO_SCREEN_SCALE_FACTOR       = "1";
    XCURSOR_THEME                     = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE                      = "24";
    MOZ_ENABLE_WAYLAND                = "1";
    XDG_CURRENT_DESKTOP               = "niri";
    XDG_SESSION_TYPE                  = "wayland";
  };

  # ── Bluetooth ────────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ── Audio (PipeWire) ─────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Display / Wayland ────────────────────────────────────────────────────────
  services.xserver.enable = false;
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # ── TUI Login: greetd + regreet ──────────────────────────────────────────────
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri";
        user = "greeter";
      };
    };
  };

  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = "/etc/greetd/background.jpg";
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
      };
    };
  };

  # ── Security / Keyring ───────────────────────────────────────────────────────
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # ── SSH ──────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── Power ────────────────────────────────────────────────────────────────────
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # ── Shell: fish ──────────────────────────────────────────────────────────────
  programs.fish.enable = true;

  # ── Users ────────────────────────────────────────────────────────────────────
  users.users.otakuracer = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "input" "wheel" "networkmanager" "video" "audio" "libvirtd" "kvm" ];
  };

  # ── Virtualisation ───────────────────────────────────────────────────────────
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package         = pkgs.qemu_kvm;
      runAsRoot       = true;
      swtpm.enable    = true;
      vhostUserPackages = with pkgs; [ virtiofsd ];
    };
  };

  programs.virt-manager.enable = true;
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  systemd.services."virt-secret-init-encryption".serviceConfig = {
    ExecStart = lib.mkForce [
      ""
      "${pkgs.bash}/bin/sh -c 'umask 0077 && mkdir -p /var/lib/libvirt/secrets && (dd if=/dev/random status=none bs=32 count=1 | systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key)'"
    ];
  };

  # ── Flatpak ──────────────────────────────────────────────────────────────────
  services.flatpak.enable = true;

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

  programs.gpu-screen-recorder.enable = true;

  # ── File Manager: Thunar ─────────────────────────────────────────────────────
  services.tumbler.enable = true;
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-volman
    thunar-archive-plugin
  ];

  # ── MIME defaults ────────────────────────────────────────────────────────────
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    inode/directory=thunar.desktop

    application/zip=engrampa.desktop
    application/x-tar=engrampa.desktop
    application/x-bzip2=engrampa.desktop
    application/x-gzip=engrampa.desktop
    application/x-7z-compressed=engrampa.desktop
    application/x-xz=engrampa.desktop
    application/x-rar=engrampa.desktop
    application/x-rar-compressed=engrampa.desktop
    application/x-arj=engrampa.desktop
    application/x-cab=engrampa.desktop
    application/x-lzip=engrampa.desktop
    application/x-iso9660-image=engrampa.desktop
    application/x-rpm=engrampa.desktop
    application/x-zstd-compressed-tar=engrampa.desktop
    application/zstd=engrampa.desktop
  '';

  # ── System Packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Terminal
    alacritty
    fish

    # Editor + LSP
    neovim
    nixd
    lua-language-server
    nodePackages.bash-language-server
    qt6.qtdeclarative  # qmlls

    # Clipboard
    cliphist
    wl-clipboard

    # Wayland / Display
    wlr-randr
    xwayland-satellite

    # Screenshot
    grim
    slurp

    # Screen recording
    gpu-screen-recorder
    gpu-screen-recorder-gtk

    # File Manager: Thunar stack
    thunar
    thunar-volman
    thunar-archive-plugin
    tumbler
    ffmpegthumbnailer
    poppler

    # Archiver
    engrampa

    # Media
    playerctl
    mpv
    celluloid
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav

    # Viewers
    imv
    zathura

    # System tools
    lxqt.lxqt-policykit
    seahorse
    libsecret

    # Qt theming
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugins

    # Theming: Catppuccin
    catppuccin-gtk
    catppuccin-papirus-folders
    catppuccin-cursors
    papirus-icon-theme

    # Samba / Network shares
    samba
    cifs-utils
    dnsmasq

    # CLI / TUI tools
    yazi
    bat
    btop
    cava
    fastfetch
    pfetch
    unar
    jq
    fd
    ripgrep
    fzf
    zoxide
    imagemagick
    nodejs
    wget
    glmark2

    # Apps
    alacritty
    firefox
    feishin
    onlyoffice-desktopeditors
    telegram-desktop
    pavucontrol
    git
    rofi
    cage

    # Quickshell (from flake input)
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ── Fonts ────────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  # ── Misc ─────────────────────────────────────────────────────────────────────
  programs.nix-ld.enable = true;
  services.gvfs.enable = true;

  system.stateVersion = "25.11";
}
