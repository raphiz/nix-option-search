{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    devsh = lib.options.mkOption {
      type = lib.types.package;
      description = "the devshell";
      internal = true;
    };
    packages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
    };
    home.packages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
    };
    environment.defaultPackages = lib.options.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
    };
  };
  config = {
    documentation.option-search.enable = true;
    devsh = pkgs.mkShellNoCC {
      buildInputs = config.packages or [];
    };
  };
}
