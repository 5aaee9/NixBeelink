{ nixpkgs }:

with nixpkgs;

{
  beelink-uboot = callPackage ./uboot.nix { };
}
