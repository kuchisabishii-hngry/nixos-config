{ config, pkgs, ... }:
let
home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
in
{
    imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
    ];

    home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        backupFileExtension = "backup";
        users.otakuracer = import ./home.nix;
    };

    #System Settings
    nixpkgs.config.allowUnfree = true;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.hostName = "nixos-x450jf";
    networking.networkmanager.enable = true;
    time.timeZone = "Asia/Jakarta";

    #GPU Force Intel - blacklist Nvidia
    #services.xserver.videoDrivers = [ "modesetting" ];
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

    #TUI Login
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri";
          user = "greeter";
        };
      };
    };

    #Essential for Wayland Portals (used by niri)
    xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk ];
    };

    programs.niri.enable = true;
    programs.thunar.enable = true;
    services.gvfs.enable = true;
    services.pipewire = {
        enable = true;
        pulse.enable = true;
    };

    #ZRAM n SWAP
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

    #Package List
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
    git
    firefox
    waybar
    rofi
    pavucontrol
    btop
    feishin
    featherpad
    glmark2
    greetd
    ghostty
    onlyoffice-desktopeditors
    peazip
    ];

    system.stateVersion = "25.11";
}

