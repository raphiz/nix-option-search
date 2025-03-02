# TUI for nix module options search

This flake provides the `nix-option-search` command to efficiently search for
available options using `fzf`.

This tool directly uses the options of your module configuration. It therefore
cannot have a version mismatch and also shows your locally defined custom
options or any other additional options.

## Usage

- Simply run `nix-options-search` to interactively explore all options in fzf.
- ctrl-v: View the nix file that defines the selected option
- ctrl-u: Go up to the parent key of the current selected option


## Installation (using nix flakes)

Configure the dependency via flake input

```nix
inputs.nix-option-search.url = "github:ciderale/nix-option-search";
```

and add the provided `inputs.nix-option-search.nixosModules.default` in
the `imports` list of one of your modules, e.g.

```nix
outputs = inputs @ { nix-option-search, ... }:

# ..somewhere in one of your modules..
{ imports = [nix-option-search.nixosModules.default]; }
```

Note: This module works not only with NixOS, but also with home-manager
and other frameworks building on the nixos modules systems (like devenv.sh).
The module is defined in `nixosModules` only to adhere to official flakes schema.

## Summary of the configuration options

The provided module defines options in `options.docs.option-search`:

- `json`: (package) the derivation containing the (nixos) option.json
- `name`: (string) the name of the option-search wrapper command
- `package`: (package) the cli tool bundled `name` bundled with `option.json`
- `add-to-packages`: (boolean) by default, add cli tool to the relevant packages options
	- added to `environment.defaultPackages` for nixos
	- added to `home.packages` for home-manager
	- added to `packages` for devenv.sh
