#!/bin/bash
# Extract a markdown section from a file given a tab-delimited fzf entry.
# Usage: extract_section.sh <filepath><TAB><line_num><TAB><line_content>
#
# Finds the nearest preceding header for the given line number, extracts the
# full section (up to the next header of same or higher level), balances code
# fences, and pipes the result to the renderer ($MDPRINT) on stdin.

set -euo pipefail

MDPRINT="${MDPRINT:-$HOME/dotfiles/scripts/mdprint.sh}"

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <filepath><TAB><line_num><TAB><line_content>" >&2
  exit 1
fi

IFS=$'\t' read -r filepath line_num _ <<< "$1"

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

# Print from the header until the next header of the same or higher level.
# With no preceding header (start=0), print from line 1 until the first header.
# Headers inside code blocks are ignored; an unclosed fence is closed at the end.
awk -v start="${header_line:-0}" '
  NR < start { next }
  NR == start {
    match($0, /^#+/)
    level=RLENGTH
    print
    next
  }
  /^```/ {
    in_code_block = !in_code_block
    print
    next
  }
  !in_code_block && /^#/ {
    match($0, /^#+/)
    if (start == 0 || RLENGTH <= level) exit
  }
  { print }
  END { if (in_code_block) print "```" }
' "$filepath" | "$MDPRINT"
