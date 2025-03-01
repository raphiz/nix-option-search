{
  description = "Nix Module Option Search";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
      (system: function nixpkgs.legacyPackages.${system});
  in {
    nixosModules.optionsearch = ./module.nix;
    packages = forAllSystems (pkgs: rec {
      optionsearch = pkgs.callPackage ./optionsearch.nix {};
      default = optionsearch;
    });
    devShells = forAllSystems (pkgs: {
      default =
        (nixpkgs.lib.modules.evalModules {
          modules = [self.nixosModules.optionsearch ./test.nix];
          specialArgs = {inherit pkgs;};
        })
        .config
        .devsh;
    });
    #debug = forAllSystems (pkgs: {
    #  default = nixpkgs.lib.modules.evalModules {
    #    modules = [self.nixosModules.optionsearch ./test.nix];
    #    specialArgs = {inherit pkgs;};
    #  };
    #});
  };
}
