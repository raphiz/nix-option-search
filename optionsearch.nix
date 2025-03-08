{
  writeShellApplication,
  jq,
  fzf,
  nix,
  gnused,
  coreutils,
  nixosOptionsDoc,
  runCommand,
  lib,
}: {
  cli = writeShellApplication {
    name = "optionsearch";
    runtimeInputs = [jq fzf nix gnused coreutils];
    text = builtins.readFile ./optionsearch.sh;
  };
  documentOptions = {
    options,
    dropPrefix,
  }: let
    optionsDoc = nixosOptionsDoc {
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
        // {name = dropPrefix option.name;}
        // lib.optionalAttrs (option ? default) {
          default = handleUnsupported option.default;
        }
        // lib.optionalAttrs (option ? example) {
          example = handleUnsupported option.example;
        };
    };
    jsonPath = "/share/doc/nixos/options.json";
    optionsDocJSON = optionsDoc.optionsJSON;
    optionsJSON = runCommand "options.json" {} ''
      cp ${optionsDocJSON}/${jsonPath} $out;
    '';
  in
    optionsJSON;
}
