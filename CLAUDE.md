`GUIDELINES.md` is the source of truth for how the tool behaves. When the code, tests or other docs disagree with it, change them to match. Change `GUIDELINES.md` only when asked.

# Scripts

## fuzzy_cheatsheet.sh

Fuzzy-search all markdown files under a configurable directory (`SEARCH_DIR`) and display the section containing the selected line, rendered via `$MDPRINT`.

### Modes

- **Interactive** (`fuzzy_cheatsheet.sh`): fzf with a live preview; Enter prints the section. Case-insensitive (`-i`).
- **Query** (`fuzzy_cheatsheet.sh <query...>`): `fzf --filter "$*" -i | head -1` prints the section for the top-ranked match without opening fzf. If nothing matches, prints `No match for: <query>` to stderr and exits 1.

### How it works

1. **Startup checks**: resolves its own path with `readlink -f`, so it works when invoked through a symlink, and expects `extract_section.sh` in the same directory. Exits 1 if `extract_section.sh` or `SEARCH_DIR` is missing.
2. **Input generation**: single `find -L | xargs awk` pass over all `.md` files under `SEARCH_DIR` (`-L` follows symlinks). Builds fzf entries in the format `filepath<TAB>line_number<TAB>line_content`. Header lines (`^#` outside code fences) are printed as they are found; all other non-empty lines are buffered in an array and printed in `END`, so headers come first. Fence state resets at the start of each file.
3. **fzf**: displays only the line content (`--with-nth 3..`), so searches match line text, not file names. The filepath and line number are carried as hidden fields for the preview and selection logic. The headers-first input order is what you see before typing; once there is a query, fzf sorts by score and input order only breaks ties.
4. **Preview**: `CLICOLOR_FORCE=1 "$EXTRACT" {}`. `EXTRACT` is exported so the preview string can reference it quoted whatever `$SHELL` is (fzf runs previews with `$SHELL -c`). `CLICOLOR_FORCE=1` keeps colour even though the preview's stdout isn't a terminal.
5. **Selection output**: calls `extract_section.sh` on the selected entry.

## extract_section.sh

Standalone helper that extracts and renders a markdown section. Takes a single tab-delimited argument (`filepath<TAB>line_num<TAB>line_content`, split with `IFS=$'\t' read`), finds the nearest preceding header, extracts the section with awk, balances code fences, and pipes the result to `$MDPRINT` on stdin. Prints usage and exits 1 unless given exactly one argument.

Used by both the fzf preview and the final selection output in `fuzzy_cheatsheet.sh`.

### Section extraction (awk)

- A first pass finds the last header at or before `line_num`, skipping code blocks.
- The second pass starts at that line number (`NR == start`), not by pattern matching, to avoid ambiguity with duplicate headers.
- Tracks the header level (`##` = 2, `###` = 3, etc.) and prints all lines until a header of the same or higher level outside a code block, so subsections are included.
- If there is no preceding header (the line is above the file's first header), `start=0` and it prints from line 1 up to the first header outside a code block.
- Tracks code block fences (`` ``` ``) to avoid treating headers inside code blocks as real headers. If the output ends inside a code block, `END` prints a closing `` ``` ``.

### Key design decisions

- **Tab-delimited fields with line numbers**: the line number pins the exact occurrence, so repeated lines (such as the many `` ```bash `` lines) and duplicate headers resolve to the right section.
- **Renderer reads stdin, no temp file**: concurrent runs (a preview and the final output, or two terminals) share no state, and nothing is left in `/tmp`. Any `MDPRINT` replacement must read markdown from stdin.
- **Fence balancing**: ensures the renderer always receives valid markdown even if the source file has an unclosed fence.
- **Headers printed immediately, content buffered in an array**: building one large string by repeated concatenation is quadratic in awk; the array keeps input generation linear.
- **`extract_section.sh` is a separate script**: the preview and the final output share one code path, and nothing is generated at runtime.

### Limitations

- Header detection is `^#`: any line starting with `#` outside a code block counts, including `#!/bin/bash` or `#tag`. Setext headers (`===`/`---` underlines) aren't recognised.
- Only `` ``` `` fences at the start of a line are recognised; `~~~` and indented fences aren't.
- Fence lines (`` ```bash ``) are listed as search entries.
- If there are enough files that `xargs` splits them across several awk runs (BSD `xargs` passes at most 5000 per run), headers-first ordering only holds within each run.

### Dependencies

- `fzf` for fuzzy selection
- `MDPRINT` env var for the markdown renderer, which must read from stdin (defaults to `$HOME/dotfiles/scripts/mdprint.sh`; `MDPRINT=cat` gives plain text)
- `SEARCH_DIR` env var controls which directory is searched (defaults to `~/dotfiles/docs/`)
- `readlink -f` (GNU coreutils, or macOS 12.3+)

## test.sh

Regression tests. Runs query mode and `extract_section.sh` against `docs/` with `MDPRINT=cat`, comparing output and exit codes. Covers subsection extraction, headers inside code blocks, case-insensitive queries, repeated lines, text before the first header, unclosed fences, error messages, and invocation through a symlink. It doesn't exercise the interactive fzf UI or the preview. Run `./test.sh`; it exits non-zero if any test fails.

### Test files

`docs/` (project-local) contains mock markdown files for testing (5 in root, 1 each in `sub-a/` and `sub-b/`). `docs/edge-cases.md` is malformed on purpose: it has text before its first header and ends inside an unclosed code fence. `test.sh` expectations depend on the exact content and line numbers of these files. Use `SEARCH_DIR=docs/` to test interactively.
