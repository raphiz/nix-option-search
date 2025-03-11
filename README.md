# TUI for nix module options search

The goal of `nix-option-search` is to efficiently search through options
provided by the nix module system. https://search.nixos.org/options is very
nice, but works only for nixos options. But there are others like home-manager,
devenv, kubenix, etc., and probably more to come. nix-option-search is one 
command line tool to search them all.

The approach is to build `options.json` and interactively explore them using
[fzf](https://junegunn.github.io/fzf/). Fzf allows for efficient filtering
and detailed option previews. Simple, yet effective.

The extensibility is a key feature of the nix module system. It is simple to
(locally) define additional options or even entirely new (convenience) modules.
Those module options are simply not present in an online system. That is a
problem `nix-option-search` tries to address. The aim is to extract
`options.json` from the locally defined setup where all module options are
available. This avoids version mismatches and you always explore exactly the
option that are available.

NOTE: The tools is still in an experimental stage. That means, it can be used,
but things like key-bindings, preview format, and the module-based integration
are subject to change.

# Standalone Usage

```sh
nix run github:ciderale/nix-option-search [module-system]
```

The currently supported module systems are "nixos", "home-manager", "devenv", or "kubenix".
If no argument is provided, a prompt allows for selecting the module system using fzf.

nix-option-search then allows for interactive exploration of the module
options. There is an detailed preview for the selected option. Help on
additional key-bindings is optained by pressing CTRL-?.

# Module Integration (Experimental, subject to changes)

This tool directly uses the options of your module configuration. It therefore
cannot have a version mismatch and also shows your locally defined custom
options or any other additional options.


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
      inputs.nix-option-search.modules.flake-parts # add this line
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

# Standalone search commands (flake package outputs)

- nix-option-search (default)
  - wrapper including 'nixos', 'home-manager', 'devenv', 'kubenix' options
  - always builds the option.json from the latest github revision
- nix-option-search-cli
  - without any wrapper for options.json
- nix-package-search: search nixpkgs using fzf (based on `nix-search`)
  - set NIXPGS_EXPR (default nixpkgs) to define the version to search
