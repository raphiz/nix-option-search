{
  pkgs,
  lib,
  options,
  config,
  ...
}: let
  cfg = config.docs;
  search = pkgs.callPackage ./optionsearch.nix {};
  jsonPath = "/share/doc/nixos/options.json";
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/lib/make-options-doc/default.nix
  optionsDoc = pkgs.nixosOptionsDoc {
    inherit options;
    warningsAreErrors = false;
  };
in {
  options.docs = {
    options-json = lib.options.mkOption {
      type = lib.types.package;
      default = optionsDoc.optionsJSON;
      description = ''
        Configuration options documentation based on nixos module system.

        The actual json file is located at ${jsonPath}.

        For details see: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/lib/make-options-doc/default.nix
      '';
    };
    option-search-name = lib.options.mkOption {
      type = lib.types.str;
      default = "docs";
      description = "The name of the option-search wrapper command";
    };
    option-search = lib.options.mkOption {
      type = lib.types.package;
      description = "devshell option search";
      default = pkgs.writeShellApplication {
        name = cfg.option-search-name;
        runtimeInputs = [search];
        text = "OPTIONS_JSON=${cfg.options-json}/${jsonPath} optionsearch";
      };
    };
    add-to-packages = lib.mkEnableOption "Add to Packages" // {default = true;};
  };
  config = lib.optionalAttrs (options ? packages) {
    packages = lib.mkIf cfg.add-to-packages [cfg.option-search];
  };
}
