#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="${1:-/tmp/lambda-gitster-prompt-lab}"

if [[ ! -d "$LAB_ROOT" ]]; then
  echo "error: lab not found at $LAB_ROOT"
  echo "run ./test_theme_states.sh first"
  exit 1
fi

cases=(clean dirty staged stash ahead behind diverged)
for c in "${cases[@]}"; do
  if [[ ! -d "$LAB_ROOT/$c" ]]; then
    echo "error: missing case directory: $LAB_ROOT/$c"
    echo "rebuild lab with ./test_theme_states.sh"
    exit 1
  fi
done

TMP_ZDOTDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_ZDOTDIR"
}
trap cleanup EXIT

cat > "$TMP_ZDOTDIR/.zshrc" <<'EOF'
source "$HOME/.zshrc"

export THEME_LAB_ROOT="${THEME_LAB_ROOT:-/tmp/lambda-gitster-prompt-lab}"
typeset -ga THEME_LAB_CASES
typeset -gi THEME_LAB_INDEX

THEME_LAB_CASES=(clean dirty staged stash ahead behind diverged)
THEME_LAB_INDEX=1

theme_case_help() {
  echo ""
  echo "Theme prompt case cycler"
  echo "  next_case   -> jump to next case directory"
  echo "  prev_case   -> jump to previous case directory"
  echo "  goto_case N -> jump by number (1..${#THEME_LAB_CASES[@]})"
  echo "  list_cases  -> show all cases"
  echo ""
}

list_cases() {
  local i=1
  for case_name in "${THEME_LAB_CASES[@]}"; do
    echo "$i) $case_name"
    ((i++))
  done
}

_goto_case_idx() {
  local idx="$1"
  local total="${#THEME_LAB_CASES[@]}"

  if (( idx < 1 || idx > total )); then
    echo "case index out of range: $idx (valid: 1..$total)"
    return 1
  fi

  THEME_LAB_INDEX="$idx"
  local case_name="${THEME_LAB_CASES[$THEME_LAB_INDEX]}"
  cd "$THEME_LAB_ROOT/$case_name" || return 1

  echo ""
  echo "=== case $THEME_LAB_INDEX/$total: $case_name ==="
  echo "git status snapshot:"
  git status --porcelain --branch | sed 's/^/  /'
  echo ""
}

goto_case() {
  if [[ -z "${1:-}" ]]; then
    echo "usage: goto_case N"
    return 1
  fi
  _goto_case_idx "$1"
}

next_case() {
  local total="${#THEME_LAB_CASES[@]}"

  if (( THEME_LAB_INDEX > total )); then
    echo "already at end; use prev_case or goto_case"
    return 0
  fi

  _goto_case_idx "$THEME_LAB_INDEX" || return 1
  ((THEME_LAB_INDEX++))
}

prev_case() {
  local target=$((THEME_LAB_INDEX - 2))
  if (( target < 1 )); then
    target=1
  fi
  _goto_case_idx "$target" || return 1
  THEME_LAB_INDEX=$((target + 1))
}

theme_case_help
next_case
EOF

echo "Launching interactive zsh case cycler..."
echo "Run next_case to advance through scenarios, then exit when done."
THEME_LAB_ROOT="$LAB_ROOT" ZDOTDIR="$TMP_ZDOTDIR" zsh -i
