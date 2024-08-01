{
  writeShellApplication,
  jq,
  fzf,
  nix,
  gnused,
  coreutils,
}:
writeShellApplication {
  name = "optionsearch";
  runtimeInputs = [jq fzf nix gnused coreutils];
  text = ''${./optionsearch.sh} "''${@}"'';
}
