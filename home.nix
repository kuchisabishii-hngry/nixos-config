{ config, pkgs, ... }:

{
  home.username = "otakuracer";
  home.homeDirectory = "/home/otakuracer";
  
  # Set this to the version you first installed. 
  # Usually "24.11" for the current stable release.
  home.stateVersion = "24.11"; 

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat
    pfetch
    fastfetch
    ghostty
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      nix-switch = "sudo nixos-rebuild switch";
    };
  };

  programs.git = {
    enable = true;
    userName  = "otakuracer";
    userEmail = "aditmadjid@gmail.com"; # Fixed the missing " here
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    EDITOR = "vim";
    TERMINAL = "ghostty";
  };
}

