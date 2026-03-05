{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];
  home.username = "otakuracer";
  home.homeDirectory = "/home/otakuracer";

  # Set this to the version you first installed.
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  
  programs.noctalia-shell = {
    enable = true;
    package = lib.mkForce (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default);
  };

  home.packages = with pkgs; [
    bat
    pfetch
    fastfetch
    ghostty
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      swtch = "sudo nixos-rebuild switch";
      swfl = "sudo nixos-rebuild switch --flake /home/otakuracer/nixos-config#nixos-x450jf";
      conf = "vim ~/nixos-config/configuration.nix";
      home = "vim ~/nixos-config/home.nix";
      flk = "vim ~/nixos-config/flake.nix";
      nix-gc = "sudo nix-collect-garbage -d";
      nix-list = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      nircon = "vim ~/.config/niri/config.kdl";
    };
  };

  programs.git = {
    enable = true;
    settings.user.name  = "otakuracer";
    settings.user.email = "aditmadjid@gmail.com";
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    EDITOR = "vim";
    TERMINAL = "ghostty";
  };

  # User-specific Ark default (optional)
  xdg.configFile."mimeapps.list".text = ''
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
}
