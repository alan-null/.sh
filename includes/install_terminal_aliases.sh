#!/bin/bash

function install_terminal_aliases() {
    local install_dir=$1
    local zshrc=$2
    echo "→ Installing terminal aliases in $zshrc from $install_dir"

    local line="[[ -f \"$install_dir/aliases/terminal.sh\" ]] && source \"$install_dir/aliases/terminal.sh\""
    grep -qxF "$line" "$zshrc" || echo "$line" >> "$zshrc"
    echo "→ terminal aliases installed"
}