{ config, pkgs, ... }:

{
  home.username = "otakuracer";
  home.homeDirectory = "/home/otakuracer";
  
  # Set this to the version you first installed. 
  home.stateVersion = "25.11"; 

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
      swtch = "sudo nixos-rebuild switch";
      nix-gc = "sudo nix-collect-garbage -d";
      nix-list = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    };
  };

  programs.git = {
    enable = true;
    userName  = "otakuracer";
    userEmail = "aditmadjid@gmail.com";
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    EDITOR = "vim";
    TERMINAL = "ghostty";
  };
}
