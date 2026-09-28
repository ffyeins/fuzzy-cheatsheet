#!/bin/bash
set -uo pipefail

# Resolve symlinks so the helper scripts are found next to the real script
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SEARCH_DIR="${SEARCH_DIR:-$HOME/dotfiles/docs/}"
EXTRACT="$SCRIPT_DIR/extract_section.sh"
LIST="$SCRIPT_DIR/list_matches.sh"

for helper in "$EXTRACT" "$LIST"; do
  if [[ ! -x "$helper" ]]; then
    echo "$(basename "$helper") not found at $helper" >&2
    exit 1
  fi
done

if [[ ! -d "$SEARCH_DIR" ]]; then
  echo "SEARCH_DIR not found: $SEARCH_DIR" >&2
  exit 1
fi

# Exported so the preview and reload commands can reference them quoted,
# whatever $SHELL is, and so list_matches.sh searches the same directory
export EXTRACT LIST SEARCH_DIR

# list_matches.sh prints filepath<TAB>line_number<TAB>line_content entries:
# headings first, then other lines, each group ranked best match first.
# fzf can't rank in groups itself, so interactive mode reloads the list on every
# query change and --no-sort keeps that order; fzf still filters and highlights.
# shellcheck disable=SC2016  # single quotes are intended: $LIST, $EXTRACT expand in fzf's shell
{
  if [[ $# -gt 0 ]]; then
    "$LIST" "$*" | head -1
  else
    "$LIST" | fzf --delimiter '\t' \
        --with-nth 3.. \
        --bind 'change:reload-sync:"$LIST" {q} || true' \
        --preview 'CLICOLOR_FORCE=1 "$EXTRACT" {}' \
        --preview-window=right:60%:wrap \
        --no-sort \
        --exact \
        -i
  fi
} | {
  IFS= read -r selection

  if [[ -n "$selection" ]]; then
    "$EXTRACT" "$selection"
  elif [[ $# -gt 0 ]]; then
    echo "No match for: $*" >&2
    exit 1
  fi
}
