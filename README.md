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

Installation and activation requires three steps:

- configure the dependency via flake input
- import _one_ of the provided modules in your modules
  - flake-parts: provides `output.packages.*.flake-parts-option-search`
  - flake-parts-devenv: adds options to enable option-search in your devShells
  - default: fallback, for use in nixos, home-manager, devenv.sh, etc.
- activate option-search via `documentation.option-search.enable`

### Configure flake input

```nix
inputs = {
	nix-option-search.url = "github:ciderale/nix-option-search";
	nix-option-search.inputs.nixpkgs.follows = "nixpkgs";
};
```

### Generic default module

Add the module `inputs.nix-option-search.modules.default` to your modules
import list and enable the provided `documentation-option-search.enable`
option:

```nix
{pkgs, ...}: {
	imports = [inputs.nix-option-search.modules.default];
  documentation.option-search.enable = true;
}
```

The `inputs.nix-options-search` can be provided by different means:

- via lexical closure (when the module is defined directly in flake.nix
- via `specialArgs = {inherit inputs;}` construct in `lib.evalModule`
- via additional argument in flakes module `inputs: {pkgs,...}: {`

The `modules.flake-parts-devenv` simplifies this step as it directly
injects the module into the devenv configurations imports.

This works for popular module systems, like nixos, home-manager, devenv.sh,
and places the `nix-options-search` binary in the corresponding package installation
option (e.g. `packages`, `home.packages`, `environment.defaultPackages`). For
others, the binary is available via internal `documentation.packages` option.


### Flake-Parts Setup with Devenv.sh shells

The module `nix-option-search.modules.flake-parts-devenv` has to be added to
flake-parts `imports` list. This automatically adds the `modules.default` to
the devenv `imports` list and makes the documentation options available:

```nix
outputs = inputs @ { flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      inputs.devenv.flakeModule
      inputs.nix-option-search.modules.flake-parts-devenv # add this line
    ];
    devenv.shells.default = {
      # .. in some of your devenv module configurations ..
      documentation.option-search.enable = true;
      documentation.option-search.flake-parts.enable = true;
    }
  };
}
```

The flake-parts-devenv module provides two option-search tools:

- `nix-options-search`: only devenv module options without the flake-parts (prefix).
- `flake-parts-options-search`: all flake-parts options, including devenv module options (but prefixed).

The latter is helpful when using flake-parts modules other than devenv.sh


### Flake-Parts Setup (without Devenv.sh)

The module `nix-option-search.modules.flake-parts` exports the `flake-parts-options-search`
package via `outputs.packages.$arch.flake-parts-option-search`. It can be run with
`nix run .#flake-parts-option-search` or accessed in perSystem configuration via
`config.packages.flake-parts-option-search`.


```nix
outputs = inputs @ { flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      inputs.nix-option-search.modules.flake-parts-devenv # add this line
    ];
  };
  perSystem = {config,...}: {
    # use `config.packages.flake-parts-option-search`
  };
}
```

## Summary of the configuration options

The provided module defines options in `options.documentation.option-search`:

- enable: (boolean) add cli tool to the relevant packages options
	- added to `environment.defaultPackages` for nixos
	- added to `home.packages` for home-manager
	- added to `packages` for devenv.sh
- `name`: (string) the name of the nix-option-search wrapper command
- `package`: (package) the cli tool bundled `name` bundled with `option.json`

# Standalone search commands

The flake defines output derivation for various module systems referring to
the lastest flake version available:

- nixos-option-search
- devenv-option-search
- home-manager-option-search
- kubenix-option-search

Additionally, there are:

- nix-package-search: point env variable OPTION_JSON to an "option.json" file
- any-option-search: define OPTION_JSON_EXPRESSION & OPTION_JSON_EXPRESSION
    - e.g. `OPTION_JSON_EXPRESSION='github:hall/kubenix#docs' OPTION_JSON_PATH="" nix run .\#any-option-search`
- nix-option-search: search nixpkgs packages
  - the NIXPGS_EXPR (default nixpkgs) defines which version to search through
