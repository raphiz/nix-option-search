#!/usr/bin/env bash
# set -x #debugging

OPTIONSEARCH=$0

SEARCH=${SEARCH:-keys}
if [ "$SEARCH" == 'keys' ]; then
      ## index only by "option-key"
      function formatOptions() {
            JQ_COMMAND="keys[]"
            jq -r "$JQ_COMMAND" < "${OPTIONS_JSON}"
      }
else
      ## index only by "option-key & description" (two-line display)
      function formatOptions() {
            JQ_COMMAND='to_entries|map({key: .key, value: (.value.description // empty) | gsub("\\n"; "")}) | map(.key + "\t" + .value) | .[]'
            jq -r "$JQ_COMMAND" < "${OPTIONS_JSON}" | sed -e 's/$/\t/'
      }
fi

# the fzf search wrapper
function search() {
      formatOptions \
            | tr '\n\t' '\0\n' \
            | fzf --read0 --exact \
            --reverse \
            --no-sort \
            --prompt="Nix Module Options (Press ? for help)> " \
            --bind '?:preview:echo -e "ctrl-v view source file\nctrl-u go to parent path of current option"' \
            --preview="bash $OPTIONSEARCH preview {}" \
            --preview-window=wrap,up \
            --bind="ctrl-u:become(bash $OPTIONSEARCH refine {} {q} )" \
            --bind="ctrl-v:become(bash $OPTIONSEARCH source {} {q} )" \
            --query "$QUERY"
}

function extract_name() {
      echo "$1" | sed -e '1q' | sed -e 's/\t.*//' # key only (no detail line)
}

function raw_entry() {
      # shellcheck disable=SC2001
      NAME_ESCAPED=$(echo "$NAME" | sed -e 's?"?\\"?g') # double-quote needs quoting in jq
      jq ".\"$NAME_ESCAPED\"" < "${OPTIONS_JSON}"
}



if [ $# == 0 ]; then

      if [ "${OPTIONS_JSON:-}" == "" ]; then
            echo "Missing OPTIONS_JSON. Define path via env var or select source:"
            echo "  for nixos:        $OPTIONSEARCH nixos"
            echo "  for devenv:       $OPTIONSEARCH devenv"
            echo "  for kubenix:      $OPTIONSEARCH k    (or kubenix)"
            echo "  for home-manager: $OPTIONSEARCH hm   (or home-manager)"
            echo ""
            echo "keybindings in search: ctrl-g: refine to given selection"
            echo "EnvVar: SEARCH=keys or description: index key only or including description"
            exit 1
      fi

      QUERY="" search
elif [ "$1" == "source" ]; then
      shift 1;
      NAME=$(extract_name "$1")
      RAW=$(raw_entry)
      DECLARATION=$(echo "$RAW" | jq -r '.declarations[]')
      exec vim "$DECLARATION"

elif [ "$1" == "preview" ]; then
      # set -x # debugging
      shift 1;
      NAME=$(extract_name "$1")
      RAW=$(raw_entry)
      TYPE=$(echo "$RAW" | jq -r .type)
      DESCRIPTION=$(echo "$RAW" | jq -r .description)
      DEFAULT=$(echo "$RAW" | jq -r '.default.text // empty')
      DECLARATION=$(echo "$RAW" | jq -r '.declarations[]')
      EXAMPLE=$(echo "$RAW" | jq -r '.example.text // empty')

      echo "NAME   : $NAME"
      echo "DEFAULT: $DEFAULT"
      echo "TYPE   : $TYPE"
      echo "DECLARATION   : $DECLARATION"
      echo "--------------------------------------------------------------"
      echo "DESCRIPTION:"
      echo ""
      echo "$DESCRIPTION"
      echo ""
      if [ -n "$EXAMPLE" ]; then
      echo "--------------------------------------------------------------"
      echo "EXAMPLE:"
      echo "$EXAMPLE"
      fi
      if false; then
            echo "--------------------------------------------------------------"
            echo "RAW:"
            echo ""
            echo "$RAW"
      fi

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
      JSON_DRV=$(yes "N" | nix build --no-link --print-out-paths github:cachix/devenv/v1.0.8\#devenv-docs-options-json)
      OPTIONS_JSON=$JSON_DRV/share/doc/nixos/options.json $OPTIONSEARCH
elif [ "$1" == "k" ] || [ "$1" == "kubenix" ]; then
      JSON_DRV=$(nix build github:hall/kubenix\#docs --no-link --print-out-paths)
      OPTIONS_JSON=$JSON_DRV $OPTIONSEARCH
fi;
