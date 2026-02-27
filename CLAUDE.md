# Scripts

## fuzzy_cheatsheet.sh

Fuzzy-search all markdown files under a configurable directory (`SEARCH_DIR`) and display the matching section rendered via `mdprint.sh`.

### How it works

1. **Input generation**: Single `find` + `awk` pass over all `.md` files under `SEARCH_DIR`. Builds fzf entries in the format `filepath<TAB>line_number<TAB>line_content`. Header lines (`^#`) are listed first, then all other non-empty lines, so header matches appear above content matches in fzf.
2. **fzf**: Displays only the line content (`--with-nth 3..`). The filepath and line number are carried as hidden fields for the preview and selection logic.
3. **Preview**: Calls `extract_section.sh` directly via `--preview`.
4. **Selection output**: Calls `extract_section.sh` on the selected entry, which renders via `mdprint.sh`.

## extract_section.sh

Standalone helper that extracts and renders a markdown section. Takes a single tab-delimited argument (`filepath<TAB>line_num<TAB>line_content`), finds the nearest preceding header, extracts the section with awk, balances code fences, and renders via `mdprint.sh`.

Used by both the fzf preview and the final selection output in `fuzzy_cheatsheet.sh`.

### Section extraction (awk)

- Starts at a specific line number (`NR == start`), not by pattern matching, to avoid ambiguity with duplicate headers.
- Tracks the header level (`##` = 2, `###` = 3, etc.).
- Prints all lines until it hits a header of the same or higher level (outside of code blocks).
- Tracks code block fences (`` ``` ``) to avoid treating headers inside code blocks as real headers.
- After extraction, a fence-balancing check appends a closing `` ``` `` if the count of fence lines is odd.

### Key design decisions

- **Tab-delimited fields** with line numbers: avoids re-searching the file with `grep -nF` which could match the wrong occurrence of duplicate content.
- **`--` in grep calls**: prevents lines starting with `-` from being interpreted as grep options.
- **Fence balancing**: ensures `mdprint.sh` always receives valid markdown even if the source file has unclosed fences.
- **Single-pass scanning**: one `find | awk` pipeline separates headers from content, replacing the previous two `find` invocations.
- **No runtime script generation**: `extract_section.sh` is a real file, eliminating the previous pattern of writing a preview script to `/tmp/` at runtime.

### Dependencies

- `fzf` for fuzzy selection
- `MDPRINT` env var for the markdown renderer (defaults to `$HOME/dotfiles/scripts/mdprint.sh`)
- `SEARCH_DIR` env var controls which directory is searched (defaults to `~/dotfiles/docs/`)

### Related

- `cheat.sh`: The original single-file version. Searches `~/cheatsheet.md` by headers only. Supports an exact-match argument. Uses the same awk section extraction pattern but matches by header text rather than line number.

### Test files

`docs/` (project-local) contains mock markdown files for testing (3 in root, 1 each in `sub-a/` and `sub-b/`). Use `SEARCH_DIR=docs/` to test locally.
