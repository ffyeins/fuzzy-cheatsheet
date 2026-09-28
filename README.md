# Fuzzy Cheatsheet

Search your markdown notes from the terminal. Pick any line and get the whole section it belongs to, rendered.

## Requirements

- [fzf](https://github.com/junegunn/fzf)
- A markdown renderer that reads from stdin. Defaults to `~/dotfiles/scripts/mdprint.sh`; set `MDPRINT` to use another one (`MDPRINT=cat` prints plain markdown).

## Installation

1. Create the scripts directory:

```bash
mkdir -p ~/dotfiles/scripts/fuzzy-cheatsheet
```

2. Copy the scripts. All three must be in the same directory:

```bash
cp extract_section.sh ~/dotfiles/scripts/fuzzy-cheatsheet/
cp fuzzy_cheatsheet.sh ~/dotfiles/scripts/fuzzy-cheatsheet/
cp list_matches.sh ~/dotfiles/scripts/fuzzy-cheatsheet/
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

### How search works

- A line matches when it contains what you typed, ignoring case. `git` matches `git add -A` but not `Merging Dicts`.
- If you type several words, each must appear in the line, in any order.
- Matching headings are listed first, then other matching lines. Within each group, the best match comes first.
- Only the text of each line is searched, not file names.
- Before you type, every line is listed, headings first.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `SEARCH_DIR` | `~/dotfiles/docs/` | Directory searched recursively for `.md` files. Symlinks are followed. |
| `MDPRINT` | `~/dotfiles/scripts/mdprint.sh` | Renderer. Receives the section on stdin. |

For example, `SEARCH_DIR=~/notes cheat`.

## What gets shown

- The section starts at the nearest heading above the selected line and runs until the next heading of the same or higher level, so subsections are included.
- For a line above a file's first heading, it shows the text from the top of the file down to that heading.
- Lines starting with `#` inside code blocks aren't treated as headings.
- An unclosed code block is closed so it still renders correctly.

## Limitations

- Any line starting with `#` outside a code block counts as a heading, including `#!/bin/bash` or `#tag`. Underlined headings (`===` or `---`) aren't recognised.
- Only code fences made of three backticks at the start of a line are recognised; `~~~` and indented fences aren't.
- The opening and closing fence lines of code blocks appear in the search list.

## Development

- `GUIDELINES.md` defines how the tool should behave. If the code, tests or docs disagree with it, they're wrong.
- `./test.sh` runs the regression tests against the sample notes in `docs/`.
- `SEARCH_DIR=docs/ ./fuzzy_cheatsheet.sh` tries it interactively on the sample notes.
- `SEARCH_DIR=docs/ ./list_matches.sh <query>` prints the ranked matches without opening fzf.
