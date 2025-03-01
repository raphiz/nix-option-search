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
  };
  config = {
    devsh = pkgs.mkShellNoCC {
      buildInputs = config.packages or [];
    };
  };
}
