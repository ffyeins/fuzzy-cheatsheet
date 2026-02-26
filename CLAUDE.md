# Scripts

## fuzzy_cheatsheet.sh

Fuzzy-search all markdown files under a configurable directory (`SEARCH_DIR`) and display the matching section rendered via `mdprint.sh`.

### How it works

1. **Input generation**: Recursively finds all `.md` files under `SEARCH_DIR`. Builds fzf entries in the format `filepath<TAB>line_number<TAB>line_content`. Header lines (`^#`) are listed first, then all other non-empty lines, so header matches appear above content matches in fzf.
2. **fzf**: Displays only the line content (`--with-nth 3..`). The filepath and line number are carried as hidden fields for the preview and selection logic.
3. **Preview**: A temp script (`/tmp/fuzzy_cheatsheet_preview.sh`) is written at runtime. It finds the nearest preceding header by line number, then extracts the full section using awk.
4. **Selection output**: Same awk extraction as preview, piped through `mdprint.sh`.

### Section extraction (awk)

The awk logic is shared between preview and final output:

- Starts at a specific line number (`NR == start`), not by pattern matching, to avoid ambiguity with duplicate headers.
- Tracks the header level (`##` = 2, `###` = 3, etc.).
- Prints all lines until it hits a header of the same or higher level (outside of code blocks).
- Tracks code block fences (`` ``` ``) to avoid treating headers inside code blocks as real headers.
- After extraction, a fence-balancing check appends a closing `` ``` `` if the count of fence lines is odd.

### Key design decisions

- **Tab-delimited fields** with line numbers: avoids re-searching the file with `grep -nF` which could match the wrong occurrence of duplicate content.
- **`--` in grep calls**: prevents lines starting with `-` from being interpreted as grep options.
- **Fence balancing**: ensures `mdprint.sh` always receives valid markdown even if the source file has unclosed fences.

### Dependencies

- `fzf` for fuzzy selection
- `~/dotfiles/scripts/mdprint.sh` for rendering markdown
- `SEARCH_DIR` variable (line 2) controls which directory is searched

### Related

- `cheat.sh`: The original single-file version. Searches `~/cheatsheet.md` by headers only. Supports an exact-match argument. Uses the same awk section extraction pattern but matches by header text rather than line number.

### Test files

`docs/` (project-local) contains mock markdown files for testing (3 in root, 1 each in `sub-a/` and `sub-b/`). This is the default `SEARCH_DIR`.
