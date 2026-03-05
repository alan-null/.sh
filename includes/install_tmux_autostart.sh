function install_tmux_autostart() {
    local zshrc=$1
    local line='if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then tmux attach 2>/dev/null || tmux new; fi'
    grep -qxF "$line" "$zshrc" || echo "$line" >> "$zshrc"
    echo "→ tmux autostart on SSH installed"
}