# Feature Guidelines

This file is the source of truth for how fuzzy-cheatsheet behaves. If the code, tests, README.md or CLAUDE.md disagree with it, this file is right and they need to change.

## Terms

- **Notes**: every `.md` file under `SEARCH_DIR`, searched recursively, following symlinks.
- **Heading line**: a line that starts with `#` and isn't inside a code block.
- **Body line**: any other non-empty line, including lines inside code blocks.
- **Section**: the part of a note shown for a line; see [Sections](#sections).

## Search

1. Every line of the notes is searched, headings and body lines alike.
2. Results list every heading match first, then every body match. When no heading matches, the results are the body matches.
3. Within each group, the best match comes first, using fzf's ranking.
4. A line matches when it contains the query as a substring. Letters scattered through a line don't count: `git` doesn't match `Merging Dicts`.
5. Matching ignores case.
6. A query of several space-separated words matches lines that contain every word, in any order.
7. Only line text is searched, not file names or paths.
8. These rules apply in both modes.

## Modes

### Interactive: `fuzzy_cheatsheet.sh`

- Opens fzf. Before anything is typed, every line is listed: headings first, then body lines, each group in file order.
- The list follows the search rules as you type.
- A preview pane shows the section for the highlighted line.
- Enter prints that section. Esc quits without printing anything.

### Query: `fuzzy_cheatsheet.sh <query...>`

- The arguments, joined with spaces, are the query.
- Prints the section for the top result without opening fzf.
- If nothing matches, prints `No match for: <query>` to stderr and exits with status 1.

## Sections

- A section starts at the nearest heading at or above the selected line and runs until the next heading of the same or higher level, so subsections are included.
- For a line above a file's first heading, the section runs from the top of the file down to that heading.
- If a section ends inside an unclosed code block, the block is closed so it renders correctly.
- The section is rendered by `MDPRINT`, which receives it on stdin.

## Configuration

- `SEARCH_DIR` (default `~/dotfiles/docs/`): where the notes are. If it doesn't exist, the tool prints `SEARCH_DIR not found: <dir>` to stderr and exits with status 1.
- `MDPRINT` (default `~/dotfiles/scripts/mdprint.sh`): the renderer. `MDPRINT=cat` prints plain markdown.
- The tool works when run through a symlink.
