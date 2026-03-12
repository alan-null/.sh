#!/usr/bin/env bash
trap 'exec zsh' EXIT

INSTALL_DIR="$1"
ZSHRC_CONF="$2"

# load modules
source "$INSTALL_DIR/includes/multiselect.sh"
source "$INSTALL_DIR/includes/install_git_aliases.sh"
source "$INSTALL_DIR/includes/install_terminal_aliases.sh"

# optional components — running under zsh, tty is quiet
echo "Select optional components to install:"
echo

declare -A choices
multiselect choices \
    "Aliases:" \
        "Git aliases (gpl, gph, gc, gl...)" \
        "Terminal aliases (cls, ..)" \
    "Packages:" \
        "btop (modern top replacement)" \

echo

[[ "${choices["Git aliases (gpl, gph, gc, gl...)"]}" == "true" ]] && install_git_aliases "$INSTALL_DIR" "$ZSHRC_CONF"
[[ "${choices["Terminal aliases (cls, ..)"]}" == "true" ]] && install_terminal_aliases "$INSTALL_DIR" "$ZSHRC_CONF"
[[ "${choices["btop (modern top replacement)"]}" == "true" ]] && sudo apt install -y btop && echo "→ btop installed"