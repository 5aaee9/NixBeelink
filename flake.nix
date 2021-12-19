{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        packages = import ./packages { nixpkgs = pkgs; };
      in
      {
        legacyPackages = packages;
        overlay = final: prev: packages;
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            nvfetcher
          ];
        };

        sdImage = import ./system/sdcard.nix { inherit nixpkgs packages; };
      });
}
