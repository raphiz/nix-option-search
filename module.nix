ctx @ {
  pkgs,
  lib,
  options,
  config,
  ...
}: let
  cfg = config.documentation.option-search;
  cfg2 = config.documentation.package-search;
  packages = (lib.optional cfg.enable cfg.package) ++ (lib.optional cfg2.enable cfg2.package);

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
      description = "the nix-option-search wrapper including the options.json";
      default = pkgs.writeShellApplication {
        name = cfg.name;
        runtimeInputs = [option-search];
        text = "OPTIONS_JSON=${cfg.json}/${jsonPath} optionsearch";
      };
    };
  };
  options.documentation.package-search = {
    enable = lib.mkEnableOption "nix-package-search";
    nixpkgs-expression = lib.options.mkOption {
      type = lib.types.str;
      description = ''
        flake reference to nixpkgs to be indexed.

        e.g. nixpkgs, github:nixos/nixpkgs

        Defaults to the current nixpkgs version
        if "inputs" is available in the module inputs.

        The above default is obtained by adding
           "specialArgs = {inherit inputs;};"
        in your module boostrap code. In that case, the
           "revision & narHash from inputs.nixpkgs"
        is used to index your actual nixpkgs version.
      '';
      example = "github:nixos/nixpkgs";
      default =
        if (ctx ? inputs.nixpkgs)
        then let
          nixpkgs = ctx.inputs.nixpkgs;
        in "github:nixos/nixpkgs/${nixpkgs.sourceInfo.rev}?narHash=${nixpkgs.narHash}"
        else "nixpkgs";
    };
    package = lib.options.mkOption {
      type = lib.types.package;
      description = "the nix-package-search wrapper including the nixpkgs flake reference";
      default = pkgs.writeShellApplication {
        name = "nix-package-search";
        runtimeInputs = [package-search];
        text = ''NIXPKGS_EXPR="${cfg2.nixpkgs-expression}" nix-package-search "''${@}"'';
      };
    };
  };
  config =
    lib.optionalAttrs (options ? packages) {
      packages = packages;
    }
    // lib.optionalAttrs (options ? environment.defaultPackages) {
      environment.defaultPackages = packages;
    }
    // lib.optionalAttrs (options ? home.packages) {
      home.packages = packages;
    };
}
