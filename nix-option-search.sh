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
            | fzf --exit-0 --read0 --exact \
            --reverse \
            --no-sort \
            --prompt="Nix Module Options (Press ? for help)> " \
            --bind '?:preview:echo -e "ctrl-v view source file\nctrl-u go to parent path of current option"' \
            --preview="bash $OPTIONSEARCH preview {}" \
            --preview-window=wrap,down \
            --bind="ctrl-u:become(bash $OPTIONSEARCH refine {} {q})" \
            --bind="ctrl-v:become(bash $OPTIONSEARCH source {} {q} )" \
            --track \
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
            echo "Missing OPTIONS_JSON. Define path via env var."
            echo ""
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
      READONLY=$(echo "$RAW" | jq -r 'if .readOnly then " READONLY" else "" end')

      RESET="\033[0m"
      BOLD="\033[1m"
      YELLOW="\033[33m"
      BLUE="\033[34m"

      echo -e "${BOLD}Name${RESET}\t\t: $NAME"
      echo -e "${BOLD}Default${RESET}\t\t:$READONLY $DEFAULT"
      echo -e "${BOLD}Type${RESET}\t\t: $TYPE"
      echo -e "${BOLD}Declaration${RESET}\t: ${BLUE}${DECLARATION}${RESET}"
      echo "──────────────────────────────────────────────────────────────"
      echo -e "${BOLD}Description${RESET}:"
      echo ""
      echo "$DESCRIPTION"
      echo ""
      if [ -n "$EXAMPLE" ]; then
      echo "──────────────────────────────────────────────────────────────"
      echo -e "${BOLD}Example${RESET}:"
      echo -e "$YELLOW"
      echo "$EXAMPLE"
      echo -e "$RESET"
      fi
      if false; then
            echo "──────────────────────────────────────────────────────────────"
            echo -e "${BOLD}RAW${RESET}:"
            echo ""
            echo "$RAW"
      fi

elif [ "$1" == "refine" ]; then
      shift 1;

      SELECTED="$1"
      CURRENT_QUERY="$2"

      if [ "${LAST_QUERY:-nopreviousquery}" == "$CURRENT_QUERY" ]; then
            # consecutive calls to "refine" => go one level up
            # strip away right most part with '.' or '^' as separator
            # the ^ corresponds to the top-most element
            QUERY="${CURRENT_QUERY%[\^.]*}"
      else
            # define the parent of the selection as query
            QUERY="^${SELECTED%.*}"
      fi

      LAST_QUERY="$QUERY" search
fi;
