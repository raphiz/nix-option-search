{
  pkgs,
  lib,
  options,
  config,
  ...
}: let
  cfg = config.documentation.option-search;
  packages = [cfg.package package-search];

  option-search = pkgs.callPackage ./optionsearch.nix {};
  package-search = pkgs.callPackage ./package-search.nix {};
  jsonPath = "/share/doc/nixos/options.json";
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/lib/make-options-doc/default.nix
  optionsDoc = pkgs.nixosOptionsDoc {
    inherit options;
    warningsAreErrors = false;
    # make it work for home-manager too
    transformOptions = option: let
      handleUnsupported = x: let
        tried = builtins.tryEval x;
      in
        if tried.success
        then tried.value
        else {text = "<error> typically unsupported system derivation";};
    in
      option
      // lib.optionalAttrs (option ? default) {
        default = handleUnsupported option.default;
      }
      // lib.optionalAttrs (option ? example) {
        example = handleUnsupported option.example;
      };
  };
in {
  options.documentation.option-search = {
    enable = lib.mkEnableOption "nix-option-search";
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
      default = "nix-option-search";
      description = "The name of the option-search wrapper command";
      example = "docs";
    };
    package = lib.options.mkOption {
      type = lib.types.package;
      description = "devshell option search";
      default = pkgs.writeShellApplication {
        name = cfg.name;
        runtimeInputs = [option-search];
        text = "OPTIONS_JSON=${cfg.json}/${jsonPath} optionsearch";
      };
    };
  };
  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (options ? packages) {
      packages = packages;
    }
    // lib.optionalAttrs (options ? environment.defaultPackages) {
      environment.defaultPackages = packages;
    }
    // lib.optionalAttrs (options ? home.packages) {
      home.packages = packages;
    }
  );
}
