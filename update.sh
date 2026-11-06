#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ ${1:-} == --submodules-only && $# == 1 ]]; then
    git -C "$INSTALL_DIR" submodule sync --recursive
    git -C "$INSTALL_DIR" submodule update --recursive --checkout
    printf '→ Submodules match the versions recorded by .sh.\n'
    exit 0
fi

if (( $# )); then
    printf 'Usage: %s [--submodules-only]\n' "$0" >&2
    exit 2
fi

if [[ -n $(git -C "$INSTALL_DIR" status --porcelain --untracked-files=normal) ]]; then
    printf 'Update stopped: commit or stash local changes in .sh and its submodules first.\n' >&2
    exit 1
fi

if ! git -C "$INSTALL_DIR" symbolic-ref -q HEAD >/dev/null; then
    printf 'Update stopped: .sh is on a detached HEAD; switch to a tracking branch first.\n' >&2
    exit 1
fi

if ! git -C "$INSTALL_DIR" rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
    printf 'Update stopped: the current .sh branch has no upstream configured.\n' >&2
    exit 1
fi

printf '→ Updating .sh from its current branch upstream.\n'
git -C "$INSTALL_DIR" -c submodule.recurse=false pull --ff-only

# Start the updated script in a fresh process, including when this file changed.
exec bash "$INSTALL_DIR/update.sh" --submodules-only
