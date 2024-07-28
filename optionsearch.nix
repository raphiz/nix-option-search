{
  writeShellApplication,
  jq,
  fzf,
  nix,
}:
writeShellApplication {
  name = "optionsearch";
  runtimeInputs = [jq fzf nix];
  text = ''${./optionsearch.sh} "''${@}"'';
}
