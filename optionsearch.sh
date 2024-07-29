#!/usr/bin/env bash

OPTIONSEARCH=$0

# the fzf search wrapper
function search() {
      jq -r "keys[]" < "${OPTIONS_JSON}" \
            | fzf \
            --reverse \
            --no-sort \
            --prompt="Nix Module Options> " \
            --preview="bash $OPTIONSEARCH preview {}" \
            --preview-window=wrap \
            --bind="ctrl-g:become(bash $OPTIONSEARCH refine {} {q} )" \
            --query "$QUERY"
}



if [ $# == 0 ]; then

      if [ "${OPTIONS_JSON:-}" == "" ]; then
            echo "Missing OPTIONS_JSON. Define one or select source"
            echo "  for home-manager: $OPTIONSEARCH hm"
            echo "  for nixos:        $OPTIONSEARCH nixos"
            exit 1
      fi

      QUERY="" search

elif [ "$1" == "preview" ]; then
      shift 1;
      NAME=$1

      RAW=$(jq ".\"$1\"" < "${OPTIONS_JSON}")
      TYPE=$(echo "$RAW" | jq -r .type)
      DESCRIPTION=$(echo "$RAW" | jq -r .description)
      DEFAULT=$(echo "$RAW" | jq -r .default.text)

      echo "NAME   : $NAME"
      echo "DEFAULT: $DEFAULT"
      echo "TYPE   : $TYPE"
      echo "--------------------------------------------------------------"
      echo "DESCRIPTION:"
      echo ""
      echo "$DESCRIPTION"
      echo "--------------------------------------------------------------"
      echo "RAW:"
      echo ""
      echo "$RAW"

elif [ "$1" == "refine" ]; then
      shift 1;

      SELECTED=$1
      CURRENT_QUERY=$2

      #echo "Define parent level as query"
      QUERY=^${SELECTED%.*}

      if [ "$QUERY" == "$CURRENT_QUERY" ]; then
            #echo "Move to parent if unchanged"
            QUERY=${CURRENT_QUERY%.*}
      fi

      if [ "$CURRENT_QUERY" == "$QUERY" ]; then
            #echo "Remove query if no more parent"
            QUERY=""
      fi

      search

elif [ "$1" == "hm" ] || [ "$1" == "home-manager" ]; then
      JSON_DRV=$(nix build --no-link --print-out-paths home-manager\#docs-json)
      OPTIONS_JSON=$JSON_DRV/share/doc/home-manager/options.json $OPTIONSEARCH
elif [ "$1" == "nixos" ]; then
      JSON_DRV=$(nix-build '<nixpkgs/nixos/release.nix>' -A options --no-out-link)
      OPTIONS_JSON=$JSON_DRV/share/doc/nixos/options.json $OPTIONSEARCH
elif [ "$1" == "devenv" ]; then
      JSON_DRV=$(yes "N" | nix build --no-link --print-out-paths github:cachix/devenv\#devenv-docs-options-json)
      OPTIONS_JSON=$JSON_DRV/share/doc/nixos/options.json $OPTIONSEARCH
fi;
