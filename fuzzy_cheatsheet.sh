#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEARCH_DIR="${SEARCH_DIR:-$HOME/dotfiles/docs/}"
EXTRACT="$SCRIPT_DIR/extract_section.sh"

if [[ ! -x "$EXTRACT" ]]; then
  echo "extract_section.sh not found at $EXTRACT" >&2
  exit 1
fi

# Build fzf input: headers first, then other non-empty lines
# Format: filepath<TAB>line_number<TAB>line_content
# Single find pass — awk separates headers from content
find "$SEARCH_DIR" -name '*.md' -print0 | xargs -0 awk '
  /^#/  { headers = headers FILENAME "\t" FNR "\t" $0 "\n"; next }
  NF    { content = content FILENAME "\t" FNR "\t" $0 "\n" }
  END   { printf "%s%s", headers, content }
' | fzf --delimiter '\t' \
        --with-nth 3.. \
        --preview "$EXTRACT {}" \
        --preview-window=right:60%:wrap \
        -i | {
  read -r selection

  if [[ -n "$selection" ]]; then
    "$EXTRACT" "$selection"
    rm -f /tmp/fuzzy_cheatsheet_section.md
  fi
}
