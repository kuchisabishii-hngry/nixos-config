{
  description = "NixOS config — HP ProDesk 600 G4 Mini (600g4-nixos)";

  inputs = {
    # ── Core ──────────────────────────────────────────────────────────────────
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # ── Home Manager ──────────────────────────────────────────────────────────
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Quickshell ────────────────────────────────────────────────────────────
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Noctalia ──────────────────────────────────────────────────────────────
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Astal ─────────────────────────────────────────────────────────────────
    astal.url = "github:aylur/astal";

    # ── AGS ───────────────────────────────────────────────────────────────────
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };
  };

  outputs = { self, nixpkgs, home-manager, quickshell, noctalia, ags, astal, ... } @ inputs:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations."600g4-nixos" = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };

      modules = [
        # ── System config ───────────────────────────────────────────────────
        ./configuration.nix

        # ── Noctalia NixOS module ────────────────────────────────────────────
        noctalia.nixosModules.default

        # ── Home Manager ────────────────────────────────────────────────────
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs    = true;
            useUserPackages  = true;
            extraSpecialArgs = { inherit inputs; };
            users.otakuracer = import ./home.nix;
          };
        }
      ];
    };
  };
}
