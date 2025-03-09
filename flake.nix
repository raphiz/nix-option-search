{
  description = "Nix Module Option Search";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
      (system: function nixpkgs.legacyPackages.${system});
  in {
    nixosModules.default = ./module.nix; # deprecated, use 'modules.*'
    modules = {
      default = ./module.nix;
      flake-parts = ./parts-module.nix;
      flake-parts-devenv = ./parts-devenv-module.nix;
    };
    packages = forAllSystems (pkgs: rec {
      nix-option-search = (pkgs.callPackages ./nix-option-search.nix {}).cli;
      nix-package-search = pkgs.callPackage ./nix-package-search.nix {};
      default = nix-option-search;
    });
    devShells = forAllSystems (pkgs: {
      default =
        (nixpkgs.lib.modules.evalModules {
          modules = [self.modules.default ./test.nix];
          specialArgs = {inherit pkgs inputs;};
        })
        .config
        .devsh;
    });
    debug = forAllSystems (pkgs: {
      default = nixpkgs.lib.modules.evalModules {
        modules = [self.nixosModules.default ./test.nix];
        specialArgs = {inherit pkgs;};
      };
    });
  };
}
