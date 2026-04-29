#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="${1:-/tmp/lambda-gitster-prompt-lab}"

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required"
  exit 1
fi

create_repo_with_initial_commit() {
  local repo_path="$1"
  mkdir -p "$repo_path"
  git init -b master "$repo_path" >/dev/null 2>&1 || {
    git init "$repo_path" >/dev/null
    (
      cd "$repo_path"
      git checkout -b master >/dev/null 2>&1 || true
    )
  }

  (
    cd "$repo_path"
    git config user.name "Prompt Lab"
    git config user.email "prompt-lab@example.com"
    printf "init\n" > a.txt
    git add a.txt
    git commit -m "init" >/dev/null
  )
}

create_clone_with_identity() {
  local remote_path="$1"
  local target_path="$2"
  git clone "$remote_path" "$target_path" >/dev/null
  (
    cd "$target_path"
    git config user.name "Prompt Lab"
    git config user.email "prompt-lab@example.com"
  )
}

print_case() {
  local name="$1"
  local path="$2"
  local expect="$3"
  printf "\n[%s]\n" "$name"
  printf "path: %s\n" "$path"
  printf "expect: %s\n" "$expect"
  (
    cd "$path"
    git status --porcelain --branch | sed 's/^/  /'
  )
}

rm -rf "$LAB_ROOT"
mkdir -p "$LAB_ROOT"

echo "Building git prompt test lab in: $LAB_ROOT"

# Local-only states
create_repo_with_initial_commit "$LAB_ROOT/clean"
cp -R "$LAB_ROOT/clean" "$LAB_ROOT/dirty"
cp -R "$LAB_ROOT/clean" "$LAB_ROOT/staged"
cp -R "$LAB_ROOT/clean" "$LAB_ROOT/stash"

(
  cd "$LAB_ROOT/dirty"
  printf "dirty-change\n" >> a.txt
  printf "untracked\n" > b.txt
)

(
  cd "$LAB_ROOT/staged"
  printf "staged-change\n" >> a.txt
  git add a.txt
)

(
  cd "$LAB_ROOT/stash"
  printf "stash-change\n" >> a.txt
  printf "stash-untracked\n" > c.txt
  git stash push -u -m "prompt-lab-stash" >/dev/null
)

# Remote-tracking states
REMOTE="$LAB_ROOT/remote.git"
git init --bare "$REMOTE" >/dev/null

create_clone_with_identity "$REMOTE" "$LAB_ROOT/seed"
(
  cd "$LAB_ROOT/seed"
  git checkout -b master >/dev/null 2>&1 || git checkout master >/dev/null 2>&1 || true
  printf "seed\n" > seed.txt
  git add seed.txt
  git commit -m "seed" >/dev/null
  git push -u origin master >/dev/null
)

# Ahead-only: local commit not pushed
create_clone_with_identity "$REMOTE" "$LAB_ROOT/ahead"
(
  cd "$LAB_ROOT/ahead"
  printf "ahead\n" >> seed.txt
  git commit -am "ahead local" >/dev/null
)

# Behind-only: remote advanced elsewhere, local fetched
create_clone_with_identity "$REMOTE" "$LAB_ROOT/behind"
create_clone_with_identity "$REMOTE" "$LAB_ROOT/behind-pusher"
(
  cd "$LAB_ROOT/behind-pusher"
  printf "behind\n" >> seed.txt
  git commit -am "advance remote for behind" >/dev/null
  git push >/dev/null
)
(
  cd "$LAB_ROOT/behind"
  git fetch >/dev/null
)

# Diverged: local commit + remote commit, then fetch
create_clone_with_identity "$REMOTE" "$LAB_ROOT/diverged"
(
  cd "$LAB_ROOT/diverged"
  printf "diverged-local\n" >> seed.txt
  git commit -am "diverged local" >/dev/null
)
create_clone_with_identity "$REMOTE" "$LAB_ROOT/diverged-pusher"
(
  cd "$LAB_ROOT/diverged-pusher"
  printf "diverged-remote\n" >> seed.txt
  git commit -am "diverged remote" >/dev/null
  git push >/dev/null
)
(
  cd "$LAB_ROOT/diverged"
  git fetch >/dev/null
)

print_case "clean" "$LAB_ROOT/clean" "prompt should show clean mark only"
print_case "dirty" "$LAB_ROOT/dirty" "prompt should show dirty mark (and no untracked symbol if disabled)"
print_case "staged" "$LAB_ROOT/staged" "prompt should show staged symbol(s), usually ~ or +"
print_case "stash" "$LAB_ROOT/stash" "prompt should show stash symbol"
print_case "ahead" "$LAB_ROOT/ahead" "prompt should show ahead count, e.g. ↑1"
print_case "behind" "$LAB_ROOT/behind" "prompt should show behind count, e.g. ↓1"
print_case "diverged" "$LAB_ROOT/diverged" "prompt should show both, e.g. ↑1↓1"

cat <<EOF

Done.

To inspect prompt rendering, cd into each repo in your normal interactive shell:
  cd "$LAB_ROOT/clean"
  cd "$LAB_ROOT/dirty"
  cd "$LAB_ROOT/staged"
  cd "$LAB_ROOT/stash"
  cd "$LAB_ROOT/ahead"
  cd "$LAB_ROOT/behind"
  cd "$LAB_ROOT/diverged"

Cleanup:
  rm -rf "$LAB_ROOT"
EOF
