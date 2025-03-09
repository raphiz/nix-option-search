{
  writeShellApplication,
  nix-option-search-cli,
}: let
  nix-option-search = writeShellApplication {
    name = "nix-option-search";
    runtimeInputs = [nix-option-search-cli];
    text = ''
      function option_json_path() {
        JSON_PATH=$1
        shift
        JSON_DRV=$(nix build --no-link --print-out-paths "''${@}")
        echo "$JSON_DRV''${JSON_PATH}"
      }

      if [ -z "''${OPTIONS_JSON:-}" ]; then
        case "''${1:-usage}" in

          home-manager|hm)
            OPTIONS_JSON=$(option_json_path "/share/doc/home-manager/options.json" "home-manager#docs-json")
            ;;

          nixos)
            OPTIONS_JSON=$(option_json_path "/share/doc/nixos/options.json" --impure --expr '(import (builtins.getFlake "nixpkgs" + /nixos/release.nix) {}).options')
            ;;

          devenv)
            OPTIONS_JSON=$(option_json_path "/share/doc/nixos/options.json" "github:cachix/devenv#devenv-docs-options-json")
            ;;

          kubenix)
            OPTIONS_JSON=$(option_json_path "" "github:hall/kubenix#docs");
            ;;

          custom)
            shift 1
            echo "Using custom definition: $*"
            OPTIONS_JSON=$(option_json_path "''${@}")
            ;;

          usage|*)
            echo "Usage: $0 home-manager|hm|nixos|devenv|kubenix|custom"
            echo "  custom: arg2-*: nix build argument for options.json derivation build"
            echo "  custom: arg1  : path to options.json within the above built derivation"
            exit 1
            ;;
        esac
      fi
      export OPTIONS_JSON
      nix-option-search
    '';
  };
in {
  inherit nix-option-search;
  default = nix-option-search;
}
