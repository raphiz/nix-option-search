{
  description = "Nix Module Option Search";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = {nixpkgs, ...}: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
      (system: function nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: rec {
      optionsearch = pkgs.callPackage ./optionsearch.nix {};
      default = optionsearch;
    });
    devShells = forAllSystems (pkgs: {
      default =
        pkgs.mkShellNoCC {
        };
    });
  };
}
