{ config, pkgs, ... }:

{
  home.username = "otakuracer";
  home.homeDirectory = "/home/otakuracer";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # ---------------------------
  # Packages
  # ---------------------------
  home.packages = with pkgs; [
    bat
    pfetch
    fastfetch
    ghostty
  ];

  # ---------------------------
  # Bash shell and aliases
  # ---------------------------
  programs.bash = {
    enable = true;
    shellAliases = {
      swtch = "sudo nixos-rebuild switch";
      swfl = "sudo nixos-rebuild switch --flake /home/otakuracer/nixos-config#nixos-x450jf";
      conf  = "vim ~/nixos-config/configuration.nix";
      home  = "vim ~/nixos-config/home.nix";
      flk   = "vim ~/nixos-config/flake.nix";
      nix-gc   = "sudo nix-collect-garbage -d";
      nix-list = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      gcom     = "git add . && git commit -m \"changes\"";
      up       = "git add . && git commit -m \"changes\" && sudo nixos-rebuild switch --flake ~/nixos-config#nixos-x450jf";
    };
  };

  # ---------------------------
  # Git config
  # ---------------------------
  programs.git = {
    enable = true;
    settings.user.name  = "otakuracer";
    settings.user.email = "aditmadjid@gmail.com";
  };

  # ---------------------------
  # Session environment variables
  # ---------------------------
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND    = "1";
    XDG_CURRENT_DESKTOP   = "niri";
    XDG_SESSION_TYPE      = "wayland";
    EDITOR                = "vim";
    TERMINAL              = "ghostty";
  };
}
