{ config, pkgs, ... }:

let
  noctaliaPkg = noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  environment.systemPackages = [
    noctaliaPkg
  ];
}
