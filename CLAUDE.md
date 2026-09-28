`GUIDELINES.md` is the source of truth for how the tool behaves. When the code, tests or other docs disagree with it, change them to match. Change `GUIDELINES.md` only when asked.

# Scripts

## fuzzy_cheatsheet.sh

Search all markdown files under a configurable directory (`SEARCH_DIR`) and display the section containing the selected line, rendered via `$MDPRINT`. Matching and ranking are done by `list_matches.sh`; section extraction by `extract_section.sh`.

### Modes

- **Interactive** (`fuzzy_cheatsheet.sh`): fzf over the `list_matches.sh` output with a live preview. Every query change reloads the ranked list; Enter prints the section.
- **Query** (`fuzzy_cheatsheet.sh <query...>`): `"$LIST" "$*" | head -1` prints the section for the top result without opening fzf. If nothing matches, prints `No match for: <query>` to stderr and exits 1.

### How it works

1. **Startup checks**: resolves its own path with `readlink -f`, so it works when invoked through a symlink, and expects `extract_section.sh` and `list_matches.sh` in the same directory. Exits 1 if either helper or `SEARCH_DIR` is missing.
2. **Exports**: `EXTRACT` and `LIST` are exported so the preview and reload strings can reference them quoted whatever `$SHELL` is (fzf runs both with `$SHELL -c`). `SEARCH_DIR` is exported so `list_matches.sh` searches the same directory, default included.
3. **fzf (interactive)**: the initial input is `list_matches.sh` with no query. `--bind 'change:reload-sync:"$LIST" {q} || true'` replaces the list with the ranked matches for the new query. `--no-sort` keeps that order; fzf still filters with the same options (`--exact -i`), which keeps every reloaded line, and highlights the matches. `reload-sync` swaps the list only once the command finishes, so it doesn't flash empty. `|| true` is there because `list_matches.sh` exits 1 when nothing matches, which fzf would show as `[Command failed: ...]`. Only the line content is displayed (`--with-nth 3..`); the file path and line number are hidden fields for the preview and selection.
4. **Preview**: `CLICOLOR_FORCE=1 "$EXTRACT" {}`. `CLICOLOR_FORCE=1` keeps colour even though the preview's stdout isn't a terminal.
5. **Selection output**: calls `extract_section.sh` on the selected entry.

## list_matches.sh

Standalone helper: `list_matches.sh [query]` prints the entries that match the query as `filepath<TAB>line_number<TAB>line_content`, headings first, then body lines, each group ranked best match first. With no query, it prints every non-empty line, headings first, in file order. Exits 1 when nothing matches (fzf's status) and prints usage and exits 1 if given more than one argument. Reads `SEARCH_DIR` with the same default as `fuzzy_cheatsheet.sh`.

Used by both modes of `fuzzy_cheatsheet.sh`, so they rank the same way.

### Pipeline

1. **Input**: a single `find -L | xargs awk` pass over all `.md` files under `SEARCH_DIR` (`-L` follows symlinks). awk prints each non-empty line as `group<TAB>filepath<TAB>line_number<TAB>line_content`, where the group is `1` for a heading (`^#` outside a code fence) and `2` for anything else. Fence state resets at the start of each file.
2. **Filter and rank**: `fzf --filter "$1" -i --exact --with-nth 4..` keeps the lines containing the query and sorts them by score. Only the line content is searched, not the group, file name or line number. With an empty query, every line passes through in input order.
3. **Group**: `LC_ALL=C sort -s -t $'\t' -k1,1` is a stable sort on the group, so headings come first and fzf's ranking holds within each group. `LC_ALL=C` because BSD `sort` fails with `Illegal byte sequence` on invalid UTF-8 in a UTF-8 locale.
4. **Output**: `cut -f2-` drops the group.

## extract_section.sh

Standalone helper that extracts and renders a markdown section. Takes a single tab-delimited argument (`filepath<TAB>line_num<TAB>line_content`, split with `IFS=$'\t' read`), finds the nearest preceding heading, extracts the section with awk, balances code fences, and pipes the result to `$MDPRINT` on stdin. Prints usage and exits 1 unless given exactly one argument.

Used by both the fzf preview and the final selection output in `fuzzy_cheatsheet.sh`.

### Section extraction (awk)

- A first pass finds the last heading at or before `line_num`, skipping code blocks.
- The second pass starts at that line number (`NR == start`), not by pattern matching, to avoid ambiguity with duplicate headings.
- Tracks the heading level (`##` = 2, `###` = 3, etc.) and prints all lines until a heading of the same or higher level outside a code block, so subsections are included.
- If there is no preceding heading (the line is above the file's first heading), `start=0` and it prints from line 1 up to the first heading outside a code block.
- Tracks code block fences (`` ``` ``) to avoid treating headings inside code blocks as real headings. If the output ends inside a code block, `END` prints a closing `` ``` ``.

## Key design decisions

- **Tab-delimited fields with line numbers**: the line number pins the exact occurrence, so repeated lines (such as the many `` ```bash `` lines) and duplicate headings resolve to the right section.
- **Groups come from a tag and a stable sort, not input order**: fzf sorts by score, so input order only breaks ties. Tagging each line and sorting on the tag after fzf puts headings first whatever their score, and however `xargs` batches the files.
- **Interactive mode reloads on every query change**: fzf can't rank in groups itself, so `list_matches.sh` does the ranking and fzf runs with `--no-sort`. The cost is a full rescan of the notes on each change; edits made while fzf is open are picked up.
- **Renderer reads stdin, no temp file**: concurrent runs (a preview and the final output, or two terminals) share no state, and nothing is left in `/tmp`. Any `MDPRINT` replacement must read markdown from stdin.
- **Fence balancing**: ensures the renderer always receives valid markdown even if the source file has an unclosed fence.
- **Helpers are separate scripts**: `list_matches.sh` gives both modes one ranking code path, `extract_section.sh` gives the preview and the final output one extraction code path, and nothing is generated at runtime.

## Limitations

- Heading detection is `^#`: any line starting with `#` outside a code block counts, including `#!/bin/bash` or `#tag`. Setext headings (`===`/`---` underlines) aren't recognised.
- Only `` ``` `` fences at the start of a line are recognised; `~~~` and indented fences aren't.
- Fence lines (`` ```bash ``) are listed as search entries.
- fzf's search operators (`^`, `$`, `!`, `|`, `'`) still work in queries. With `--exact`, a leading `'` makes that word a fuzzy match, which `GUIDELINES.md` doesn't cover.

## Dependencies

- `fzf` for filtering, ranking and the interactive UI
- `MDPRINT` env var for the markdown renderer, which must read from stdin (defaults to `$HOME/dotfiles/scripts/mdprint.sh`; `MDPRINT=cat` gives plain text)
- `SEARCH_DIR` env var controls which directory is searched (defaults to `~/dotfiles/docs/`)
- `readlink -f` (GNU coreutils, or macOS 12.3+)

## test.sh

Regression tests. Runs query mode, `list_matches.sh` and `extract_section.sh` against `docs/` with `MDPRINT=cat`, comparing output and exit codes. Covers headings-first ordering with best match first within each group, substring (not fuzzy) matching, subsection extraction, headings inside code blocks, case-insensitive queries, repeated lines, text before the first heading, unclosed fences, error and usage messages, and invocation through a symlink. It doesn't exercise the interactive fzf UI, the reload or the preview. Run `./test.sh`; it exits non-zero if any test fails.

### Test files

`docs/` (project-local) contains mock markdown files for testing (5 in root, 1 each in `sub-a/` and `sub-b/`). `docs/edge-cases.md` is malformed on purpose: it has text before its first heading and ends inside an unclosed code fence. `test.sh` expectations depend on the exact content and line numbers of these files. Use `SEARCH_DIR=docs/` to test interactively.
