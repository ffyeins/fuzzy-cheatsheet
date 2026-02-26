#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEARCH_DIR="$SCRIPT_DIR/docs/"
TEMP_FILE=/tmp/fuzzy_cheatsheet_section.md
PREVIEW_SCRIPT=/tmp/fuzzy_cheatsheet_preview.sh

# Preview script: find nearest preceding header for the selected line and show it
cat > "$PREVIEW_SCRIPT" << 'PREVIEW_EOF'
#!/bin/bash
TEMP_FILE=/tmp/fuzzy_cheatsheet_section.md
input="$1"
filepath="${input%%	*}"
rest="${input#*	}"
line_num="${rest%%	*}"

if [[ ! -f "$filepath" ]]; then
  echo "File not found: $filepath"
  exit 1
fi

# Find nearest preceding header line number
header_line=$(head -n "$line_num" "$filepath" | grep -n "^#" | tail -1 | cut -d: -f1)

if [[ -z "$header_line" ]]; then
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

~/dotfiles/scripts/mdprint.sh "$TEMP_FILE"
PREVIEW_EOF

chmod +x "$PREVIEW_SCRIPT"

# Build fzf input: headers first, then other lines
# Format: filepath<TAB>line_number<TAB>line_content
{
  find "$SEARCH_DIR" -name '*.md' -print0 | while IFS= read -r -d '' file; do
    grep -n "^#" "$file" | while IFS=: read -r num line; do
      printf '%s\t%s\t%s\n' "$file" "$num" "$line"
    done
  done
  find "$SEARCH_DIR" -name '*.md' -print0 | while IFS= read -r -d '' file; do
    grep -n -v "^#" "$file" | grep -v "^[0-9]*:$" | while IFS=: read -r num line; do
      printf '%s\t%s\t%s\n' "$file" "$num" "$line"
    done
  done
} | fzf --delimiter '\t' \
        --with-nth 3.. \
        --preview "$PREVIEW_SCRIPT {}" \
        --preview-window=right:60%:wrap \
        -i | {
  read -r selection

  if [[ -n "$selection" ]]; then
    filepath="${selection%%	*}"
    rest="${selection#*	}"
    line_num="${rest%%	*}"

    # Find nearest preceding header line number
    header_line=$(head -n "$line_num" "$filepath" | grep -n "^#" | tail -1 | cut -d: -f1)

    if [[ -n "$header_line" ]]; then
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
    else
      # No preceding header, show from beginning to first header
      awk '
        /^#/ { exit }
        { print }
      ' "$filepath" > "$TEMP_FILE"
    fi

    # Close unclosed code fence
    if (( $(grep -c "^\`\`\`" "$TEMP_FILE") % 2 == 1 )); then
      echo '```' >> "$TEMP_FILE"
    fi

    ~/dotfiles/scripts/mdprint.sh "$TEMP_FILE"
    rm -f "$TEMP_FILE"
  fi
}
