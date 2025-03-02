{
  writeShellApplication,
  nix-search,
  jq,
  fzf,
}:
writeShellApplication {
  name = "nix-package-search";
  runtimeInputs = [nix-search jq fzf];
  text = ''
    LISTING='def pad(x;n): x + (" "*(x | n - length )); map([pad(.version;10), pad(.path | sub("[^.]*.";"");15), .description, .|tostring] | join("\t") )|.[]'
    DETAIL='["Path:\t\t"+.path,"Name:\t\t"+.name, "Version:\t"+.version, "",.description,"",.longDescription]|join("\n")'

    INFO="$(cat <<EOF
    First word of Query is sent to nix-search

    Additional words are filtering in fzf:
    - ! Prefix to exclude matches
    - ' To require exact matches
    EOF
    )"

    if [ "''${1:-}" = "--index" ]; then
      nix-search --index --flake "''${2:-nixpkgs}"
    elif [ $# -gt 0 ]; then
       QUERY=$(echo "$1" | cut -f1 -d ' ' | tr -d \')
       echo -e "Version  \tPackage   \tDescription"
       nix-search --json "$QUERY" | jq -r "$LISTING"
    else
      echo | fzf \
       --bind "change:+reload:sleep 0.1;$0 {q}" \
       --preview "jq -r '$DETAIL' <<< {4}" \
       --exact --reverse \
       --delimiter '\t' --with-nth ..3 --accept-nth 2 \
       --prompt="Nixpkgs Search (Press ? for help)> " \
       --bind "?:preview:echo \"$INFO\"" \
       --header-lines 1 \
       --no-hscroll \
       --preview-window=bottom,wrap \
       --tiebreak=chunk,begin
    fi
  '';
}
