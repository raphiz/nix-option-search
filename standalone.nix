{
  writeShellApplication,
  nix-search,
  jq,
  fzf,
  coreutils,
  nix-option-search,
}: {
  home-manager-option-search = writeShellApplication {
    name = "home-manager-option-search";
    runtimeInputs = [nix-option-search];
    text = ''
      JSON_DRV=$(nix build --no-link --print-out-paths home-manager\#docs-json)
      OPTIONS_JSON=$JSON_DRV/share/doc/home-manager/options.json nix-option-search
    '';
  };
  nixos-option-search = writeShellApplication {
    name = "home-manager-option-search";
    runtimeInputs = [nix-option-search];
    text = ''
      JSON_DRV=$(
          nix build --no-link --print-out-paths --impure \
          --expr '(import (builtins.getFlake "nixpkgs" + /nixos/release.nix) {}).options'
      )
      OPTIONS_JSON=$JSON_DRV/share/doc/nixos/options.json nix-option-search
    '';
  };
  devenv-option-search = writeShellApplication {
    name = "devenv-option-search";
    runtimeInputs = [nix-option-search];
    text = ''
      JSON_DRV=$(nix build --no-link --print-out-paths github:cachix/devenv#devenv-docs-options-json || echo "$?")
      OPTIONS_JSON=$JSON_DRV/share/doc/nixos/options.json nix-option-search
    '';
  };
  kubenix-option-search = writeShellApplication {
    name = "kubenix-option-search";
    runtimeInputs = [nix-option-search];
    text = ''
      JSON_DRV=$(nix build --no-link --print-out-paths github:hall/kubenix#docs)
      OPTIONS_JSON=$JSON_DRV nix-option-search
    '';
  };
}
