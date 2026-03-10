{
  description = "NixOS config — ASUS X450JF (nixos-x450jf)";
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
    # ── Zen Browser ───────────────────────────────────────────────────────────
    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager, noctalia, quickshell, zenBrowser, ... } @ inputs:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations."nixos-x450jf" = nixpkgs.lib.nixosSystem {
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
