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

  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
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
