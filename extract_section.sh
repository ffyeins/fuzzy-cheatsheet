#!/bin/bash
# Extract a markdown section from a file given a tab-delimited fzf entry.
# Usage: extract_section.sh <filepath><TAB><line_num><TAB><line_content>
#
# Finds the nearest preceding header for the given line number, extracts the
# full section (up to the next header of same or higher level), balances code
# fences, and renders via mdprint.sh.

set -euo pipefail

MDPRINT="${MDPRINT:-$HOME/dotfiles/scripts/mdprint.sh}"
TEMP_FILE=/tmp/fuzzy_cheatsheet_section.md

input="$1"
filepath="${input%%	*}"
rest="${input#*	}"
line_num="${rest%%	*}"

if [[ ! -f "$filepath" ]]; then
  echo "File not found: $filepath" >&2
  exit 1
fi

# Find nearest preceding header line number
header_line=$(awk -v end="$line_num" '
  NR > end       { exit }
  /^```/         { in_code = !in_code; next }
  !in_code && /^#/ { last = NR }
  END            { if (last) print last }
' "$filepath")

if [[ -z "$header_line" ]]; then
  # No preceding header — show from beginning to first header
  awk '
    /^#/ { exit }
    { print }
  ' "$filepath" > "$TEMP_FILE"
else
  awk -v start="$header_line" '
    NR == start {
      found=1
      match($0, /^#+/)
      level=RLENGTH
      print
      next
    }
    found {
      if (/^```/) {
        in_code_block = !in_code_block
        print
        next
      }
      if (!in_code_block && /^#/) {
        match($0, /^#+/)
        new_level=RLENGTH
        if (new_level <= level) exit
      }
      print
    }
  ' "$filepath" > "$TEMP_FILE"
fi

# Close unclosed code fence
if (( $(grep -c "^\`\`\`" "$TEMP_FILE") % 2 == 1 )); then
  echo '```' >> "$TEMP_FILE"
fi

"$MDPRINT" "$TEMP_FILE"
