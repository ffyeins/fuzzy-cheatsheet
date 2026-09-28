#!/bin/bash
# Regression tests for fuzzy_cheatsheet.sh and extract_section.sh.
# Runs query mode and extract_section.sh against the mock notes in docs/,
# with cat as the renderer so the output is plain markdown.
# Usage: ./test.sh

set -uo pipefail

cd "$(dirname "$(readlink -f "$0")")" || exit 1
export MDPRINT=cat SEARCH_DIR=docs/

pass=0
fail=0

# check <name> <expected exit code> <expected output> <command...>
# Compares combined stdout/stderr (trailing newlines ignored) and exit code.
check() {
  local name="$1" want_status="$2" want="$3"
  shift 3
  local got status
  got="$("$@" 2>&1)"
  status=$?
  if [[ "$got" == "$want" && "$status" == "$want_status" ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $name (exit $status, want $want_status)"
    diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/  /'
  fi
}

amend_section=$(cat <<'EOF'
### Amending a Commit

```bash
git commit --amend
```
EOF
)

check "query prints the matching subsection" 0 "$amend_section" \
  ./fuzzy_cheatsheet.sh amend

check "headers inside code blocks don't end the section" 0 "$(cat <<'EOF'
## Comments

In bash, comments start with `#`:

```bash
# This is a comment
echo "hello"  # inline comment
## Another comment style
### Not a heading
```

Regular text after the code block.
EOF
)" ./fuzzy_cheatsheet.sh another comment

check "query is case-insensitive and includes subsections" 0 "$(cat <<'EOF'
## SELECT

```sql
SELECT name, age FROM users WHERE active = 1;
```

### Ordering

```sql
SELECT * FROM users ORDER BY created_at DESC;
```
EOF
)" ./fuzzy_cheatsheet.sh Select

check "headings come first, then other lines, each ranked best match first" 0 \
  $'docs/git-basics.md\t14\t## Committing
docs/git-basics.md\t20\t### Amending a Commit
docs/git-basics.md\t23\tgit commit --amend
docs/git-basics.md\t17\tgit commit -m "your message"' \
  ./list_matches.sh commit

check "query picks a heading match over a body match" 0 "$(cat <<'EOF'
### With Capture Groups

```
(https?)://([\w.]+)(/.*)
```
EOF
)" ./fuzzy_cheatsheet.sh group

check "matching is substring, not fuzzy" 1 "No match for: gtbsc" \
  ./fuzzy_cheatsheet.sh gtbsc

check "list_matches.sh with more than one argument prints usage" 1 \
  "Usage: list_matches.sh [query]" \
  ./list_matches.sh a b

check "line number picks the right occurrence of a repeated line" 0 "$(cat <<'EOF'
## Branching

Create and switch to a new branch:

```bash
git checkout -b feature-branch
```

### Deleting a Branch

```bash
git branch -d old-branch
```
EOF
)" ./extract_section.sh $'docs/git-basics.md\t30\t```bash'

check "text before the first header keeps its code block" 0 "$(cat <<'EOF'
Text before the first header.

```bash
# not a header
make install
```
EOF
)" ./extract_section.sh $'docs/edge-cases.md\t1\tText before the first header.'

check "unclosed code fence is closed" 0 "$(cat <<'EOF'
## Unclosed Fence

```bash
echo "fence never closed"
```
EOF
)" ./extract_section.sh $'docs/edge-cases.md\t13\techo "fence never closed"'

check "query with no match reports it" 1 "No match for: nomatchxyz" \
  ./fuzzy_cheatsheet.sh nomatchxyz

check "missing SEARCH_DIR is reported" 1 "SEARCH_DIR not found: /nonexistent" \
  env SEARCH_DIR=/nonexistent ./fuzzy_cheatsheet.sh amend

check "extract_section.sh without arguments prints usage" 1 \
  "Usage: extract_section.sh <filepath><TAB><line_num><TAB><line_content>" \
  ./extract_section.sh

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
ln -s "$PWD/fuzzy_cheatsheet.sh" "$tmp/cheat"
check "runs through a symlink" 0 "$amend_section" "$tmp/cheat" amend

echo "$pass passed, $fail failed"
(( fail == 0 ))
