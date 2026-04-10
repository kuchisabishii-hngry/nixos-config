{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Nix Settings ────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Bootloader ───────────────────────────────────────────────────────────────
  boot.loader.limine = {
    enable = true;
    maxGenerations = 10;
    style.wallpapers = [];
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Kernel & ZRAM ────────────────────────────────────────────────────────────
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    "vm.swappiness"           = 30;
    "vm.vfs_cache_pressure"   = 50;
  };

  # ── Networking ───────────────────────────────────────────────────────────────
  networking.hostName = "600g4-nixos";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };

  # ── KDE Connect ──────────────────────────────────────────────────────────────
  programs.kdeconnect.enable = true;
  security.wrappers.kdeconnectd = {
    owner        = "root";
    group        = "root";
    capabilities = "cap_net_admin+ep";
    source       = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnectd";
  };

  # ── Locale & Time ────────────────────────────────────────────────────────────
  time.timeZone = "Asia/Jakarta";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── GPU: Intel UHD 630 (Coffee Lake) ────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver     # VAAPI for UHD 630 (iHD)
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME                   = "iHD";
    ELECTRON_OZONE_PLATFORM_HINT        = "x11";
    GTK_THEME                           = "Tokyonight-Dark";
    GTK_APPLICATION_PREFER_DARK_THEME   = "1";
    QT_QPA_PLATFORMTHEME                = "qt6ct";
    QT_AUTO_SCREEN_SCALE_FACTOR         = "1";
    XCURSOR_THEME                       = "Adwaita";
    XCURSOR_SIZE                        = "24";
    XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    ];
  };

  # ── Tailscale (VPN) ─────────────────────────────────────────────
  services.tailscale = {
      enable = true;
      extraUpFlags = [ "--accept-routes" ];
  };

  # ── Bluetooth (Intel 9560 combo) ─────────────────────────────────────────────
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
  programs.xwayland.enable = true;
  programs.hyprland = {
      enable    = true;
      withUWSM  = true;
  };


  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    config.common.default = "*";
  };

  # ── TUI Login: greetd + tuigreet ─────────────────────────────────────────────
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs.hyprland}/share/wayland-sessions";
        user = "greeter";
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

  # ── FUSE fix (important for Ferdium/Electron apps)
  programs.fuse.userAllowOther = true;

  # ── Users ────────────────────────────────────────────────────────────────────
  users.users.otakuracer = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "libvirtd" "kvm" ];
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

  # ── System Packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # AI
    #ollama-cpu

    # Terminal
    alacritty
    fish

    # Editor
    neovim
    nixd
    lua-language-server
    bash-language-server
    qt6.qtdeclarative  # provides qmlls

    # Clipboard
    cliphist
    wl-clipboard

    # Wayland / Display
    wlr-randr

    # Screenshot
    grim
    slurp

    # File Manager: Nemo
    nemo
    nemo-fileroller              # archive integration
    ffmpegthumbnailer            # video thumbnails
    poppler                      # PDF thumbnails

    # Archiver: Engrampa
    engrampa

    # Media
    playerctl                    # media key control
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav          # ffmpeg codec bridge

    # Viewers
    imv                          # image viewer (Wayland-native)
    zathura                      # PDF/document viewer

    # System tools
    lxqt.lxqt-policykit          # polkit agent (auth popups)
    seahorse                     # keyring/secrets manager UI
    libsecret                    # secret service library

    # Qt theming without Plasma
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugins

    # Theming: Catppuccin full stack
    tokyonight-gtk-theme                     # GTK theme
    papirus-icon-theme                 # base for catppuccin-papirus

    # CLI / TUI tools
    fd
    fzf
    imagemagick
    jq
    ripgrep
    unar
    zoxide

    # Video player
    mpv
    celluloid

    # Apps
    #telegram-desktop
    android-tools
    appimage-run
    btop
    deadbeef-with-plugins
    fastfetch
    ferdium
    floorp-bin
    git
    glib
    gparted
    gsettings-desktop-schemas
    ntfs3g
    onlyoffice-desktopeditors
    parabolic
    pavucontrol
    stremio-linux-shell
    spotify
    sptlrx
    uwsm
    wget
    winbox4
    xdg-utils
    yt-dlp

    # Screen recorder
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
      ];
    })

    # hyprland utilities
    hypridle
    hyprlock
    hyprshot
    libappindicator-gtk3
    libdbusmenu-gtk3
    awww
    xdg-desktop-portal-hyprland
  ];

  # ── Fonts ────────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  # ── MIME defaults ────────────────────────────────────────────────────────────
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    inode/directory=nemo.desktop

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

  # ── File Manager: Nemo ───────────────────────────────────────────────────────
  services.gvfs.enable = true;   # needed for trash, network mounts, MTP

  programs.nix-ld.enable = true;

  # ── Virtualisation: Virt-Manager + QEMU ─────────────────────────────────────
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package           = pkgs.qemu_kvm;
      runAsRoot         = true;
      swtpm.enable      = true;
      vhostUserPackages = with pkgs; [ virtiofsd ];
    };
  };

  programs.virt-manager.enable = true;

  # SPICE guest tools — shared clipboard + display resize in VM
  services.spice-vdagentd.enable = true;

  # Add user to libvirtd group — merged into users block above

  programs.dconf.enable = true;

  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # Override KDE Connect DBus service to use CAP_NET_ADMIN wrappers
  system.stateVersion = "25.11";
}
