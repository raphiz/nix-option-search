{
  pkgs,
  lib,
  options,
  config,
  ...
}: let
  cfg = config.docs.option-search;
  search = pkgs.callPackage ./optionsearch.nix {};
  jsonPath = "/share/doc/nixos/options.json";
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/lib/make-options-doc/default.nix
  optionsDoc = pkgs.nixosOptionsDoc {
    inherit options;
    warningsAreErrors = false;
    # make it work for home-manager too
    transformOptions = option:
      {
        inherit
          (option)
          name
          description
          type
          declarations
          loc
          visible
          internal
          ;
      }
      // lib.optionalAttrs (option ? default) {inherit (option) default;};
  };
in {
  options.docs.option-search = {
    json = lib.options.mkOption {
      type = lib.types.package;
      default = optionsDoc.optionsJSON;
      description = ''
        Configuration options documentation based on nixos module system.

        The actual json file is located at ${jsonPath}.

        For details see: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/lib/make-options-doc/default.nix
      '';
    };
    name = lib.options.mkOption {
      type = lib.types.str;
      default = "docs";
      description = "The name of the option-search wrapper command";
    };
    package = lib.options.mkOption {
      type = lib.types.package;
      description = "devshell option search";
      default = pkgs.writeShellApplication {
        name = cfg.name;
        runtimeInputs = [search];
        text = "OPTIONS_JSON=${cfg.json}/${jsonPath} optionsearch";
      };
    };
    add-to-packages = lib.mkEnableOption "Add to Packages" // {default = true;};
  };
  config =
    lib.optionalAttrs (options ? packages) {
      packages = lib.mkIf cfg.add-to-packages [cfg.package];
    }
    // lib.optionalAttrs (options ? home.packages) {
      home.packages = lib.mkIf cfg.add-to-packages [cfg.package];
    };
}
