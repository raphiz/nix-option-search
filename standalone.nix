{
  writeShellApplication,
  nix-option-search,
}: let
  defaultPath = "/share/doc/nixos/options.json";
  makeSearch = {
    name,
    optionJsonExpression,
    optionJsonPath ? defaultPath,
  }: let
    binName = "${name}-option-search";
  in {
    "${binName}" = writeShellApplication {
      name = binName;
      runtimeInputs = [nix-option-search];
      text = ''
        JSON_DRV=$(nix build --no-link --print-out-paths ${optionJsonExpression})
        OPTIONS_JSON=$JSON_DRV${optionJsonPath} nix-option-search
      '';
    };
  };
in
  makeSearch {
    name = "home-manager";
    optionJsonExpression = "home-manager#docs-json";
    optionJsonPath = "/share/doc/home-manager/options.json";
  }
  // makeSearch {
    name = "nixos";
    optionJsonExpression = ''--impure --expr '(import (builtins.getFlake "nixpkgs" + /nixos/release.nix) {}).options' '';
  }
  // makeSearch {
    name = "devenv";
    optionJsonExpression = "github:cachix/devenv#devenv-docs-options-json";
  }
  // makeSearch {
    name = "kubenix";
    optionJsonExpression = "github:hall/kubenix#docs";
    optionJsonPath = "";
  }
  // makeSearch {
    name = "any"; # use for other tools not listed here by setting environment variables
    # OPTION_JSON_EXPRESSION='github:hall/kubenix#docs' OPTION_JSON_PATH="" nix run .\#any-option-search
    optionJsonExpression = ''"$OPTION_JSON_EXPRESSION"'';
    optionJsonPath = ''"''${OPTION_JSON_PATH-${defaultPath}}" '';
  }
