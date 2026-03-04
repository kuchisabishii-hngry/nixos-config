{
  description = "NixOS with Niri + Noctalia (official way)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, noctalia, ... }: {
    nixosConfigurations.nixos-x450jf = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            users.otakuracer = {
              imports = [
                ./home.nix
              ];
            };
          };
        }

        # Noctalia system-wide module
        ./nixos/modules/noctalia.nix
      ];
    };
  };
}
