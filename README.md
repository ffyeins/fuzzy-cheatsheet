# Fuzzy Cheatsheet

Fuzzy-search all markdown files under a configurable directory and display the matching section rendered in the terminal.

## Installation

1. Create the scripts directory:

```bash
mkdir -p ~/dotfiles/scripts/fuzzy-cheatsheet
```

2. Copy the scripts:

```bash
cp extract_section.sh ~/dotfiles/scripts/fuzzy-cheatsheet/
cp fuzzy_cheatsheet.sh ~/dotfiles/scripts/fuzzy-cheatsheet/
```

3. Add an alias to your shell config (`~/.bashrc` or `~/.zshrc`):

```bash
alias cheat="~/dotfiles/scripts/fuzzy-cheatsheet/fuzzy_cheatsheet.sh"
```

4. Reload your shell config:

```bash
source ~/.zshrc
```
