# Fuzzy Cheatsheet

Fuzzy-search your markdown notes from the terminal. Pick any line and get the whole section it belongs to, rendered.

## Requirements

- [fzf](https://github.com/junegunn/fzf)
- A markdown renderer that reads from stdin. Defaults to `~/dotfiles/scripts/mdprint.sh`; set `MDPRINT` to use another one (`MDPRINT=cat` prints plain markdown).

## Installation

1. Create the scripts directory:

```bash
mkdir -p ~/dotfiles/scripts/fuzzy-cheatsheet
```

2. Copy the scripts. Both must be in the same directory:

```bash
cp extract_section.sh ~/dotfiles/scripts/fuzzy-cheatsheet/
cp fuzzy_cheatsheet.sh ~/dotfiles/scripts/fuzzy-cheatsheet/
```

3. Add an alias to your shell config (`~/.bashrc` or `~/.zshrc`):

```bash
alias cheat="~/dotfiles/scripts/fuzzy-cheatsheet/fuzzy_cheatsheet.sh"
```

A symlink to `fuzzy_cheatsheet.sh` somewhere on your `PATH` works too.

4. Reload your shell config:

```bash
source ~/.zshrc
```

## Usage

```bash
cheat            # interactive search with preview
cheat <query>    # print the best match directly
```

- **Interactive:** type to search every line of your notes. The right-hand pane previews the section for the highlighted line; Enter prints it, Esc quits.
- **Query:** prints the section for the top match without opening fzf, for example `cheat left join`. If nothing matches, it prints `No match for: <query>` and exits with status 1.

Search is fuzzy and case-insensitive, and matches the text of each line, not file names. Before you type, headers are listed ahead of other lines; once you type, results are ranked by how well they match.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `SEARCH_DIR` | `~/dotfiles/docs/` | Directory searched recursively for `.md` files. Symlinks are followed. |
| `MDPRINT` | `~/dotfiles/scripts/mdprint.sh` | Renderer. Receives the section on stdin. |

For example, `SEARCH_DIR=~/notes cheat`.

## What gets shown

- The section starts at the nearest header above the selected line and runs until the next header of the same or higher level, so subsections are included.
- For a line above a file's first header, it shows the text from the top of the file down to that header.
- Lines starting with `#` inside code blocks aren't treated as headers.
- An unclosed code block is closed so it still renders correctly.

## Limitations

- Any line starting with `#` outside a code block counts as a header, including `#!/bin/bash` or `#tag`. Underlined headers (`===` or `---`) aren't recognised.
- Only code fences made of three backticks at the start of a line are recognised; `~~~` and indented fences aren't.
- The opening and closing fence lines of code blocks appear in the search list.

## Development

- `./test.sh` runs the regression tests against the sample notes in `docs/`.
- `SEARCH_DIR=docs/ ./fuzzy_cheatsheet.sh` tries it interactively on the sample notes.
