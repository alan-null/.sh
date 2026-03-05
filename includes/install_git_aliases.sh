#!/bin/bash

function install_git_aliases() {
    local install_dir=$1
    local zshrc=$2
    echo "→ Installing git aliases in $zshrc from $install_dir"

    local line="[[ -f \"$install_dir/aliases/git.sh\" ]] && source \"$install_dir/aliases/git.sh\""
    grep -qxF "$line" "$zshrc" || echo "$line" >> "$zshrc"
    echo "→ Git aliases installed"
}