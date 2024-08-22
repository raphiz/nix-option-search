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
    packages = forAllSystems (pkgs: {
      optionsearch = pkgs.callPackage ./optionsearch.nix {};
    });
    #    devShells = forAllSystems (pkgs: {
    #      default =
    #        pkgs.mkShellNoCC {
    #        };
    #    });
  };
}
