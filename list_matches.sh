#!/bin/bash
# List the lines of the markdown files under $SEARCH_DIR that contain a query.
# Usage: list_matches.sh [query]
#
# Headings come first, then other non-empty lines; within each group, lines
# are ranked best match first by fzf (case-insensitive substring match). With
# no query, every line is listed, headings first, in file order.
# Output format: filepath<TAB>line_number<TAB>line_content

set -uo pipefail

SEARCH_DIR="${SEARCH_DIR:-$HOME/dotfiles/docs/}"

if [[ $# -gt 1 ]]; then
  echo "Usage: $(basename "$0") [query]" >&2
  exit 1
fi

# awk tags each line with its group (1 = heading outside a code block, 2 = other).
# fzf filters and ranks by score, then a stable sort on the tag puts headings
# first without disturbing the ranking within each group, and cut drops the tag.
# sort runs with LC_ALL=C so bytes that aren't valid UTF-8 don't make it fail.
# shellcheck disable=SC2016  # single quotes are intended: awk script
find -L "$SEARCH_DIR" -name '*.md' -print0 | xargs -0 awk '
  FNR == 1          { in_code = 0 }
  /^```/            { in_code = !in_code }
  !in_code && /^#/  { print "1\t" FILENAME "\t" FNR "\t" $0; next }
  NF                { print "2\t" FILENAME "\t" FNR "\t" $0 }
' | fzf --delimiter '\t' --with-nth 4.. --filter "${1:-}" -i --exact \
  | LC_ALL=C sort -s -t $'\t' -k1,1 \
  | cut -f2-
