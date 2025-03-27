#!/bin/bash

sudo apt update -y
sudo apt install -y curl git zsh fzf tmux

# oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    omz update
fi

# zsh theme
curl -fsSL "https://raw.githubusercontent.com/ergenekonyigit/lambda-gitster/refs/heads/main/lambda-gitster.zsh-theme" -o "$HOME/.oh-my-zsh/custom/themes/lambda-gitster.zsh-theme"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="lambda-gitster"/' "$HOME/.zshrc"

# zsh plugins
if ! grep -q "fzf" ~/.zshrc; then
    sed -i '/^plugins=/ s/)/ fzf)/' ~/.zshrc
fi

# tmux
TMUX_CONF="$HOME/.tmux.conf"
touch "$TMUX_CONF"

TMUX_SETTINGS="
# Set default shell to zsh
set-option -g default-shell $(which zsh)

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @resurrect-dir ~/.tmux/resurrect

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
"

echo "$TMUX_SETTINGS" | while read -r line; do
    grep -qxF "$line" "$TMUX_CONF" || echo "$line" >> "$TMUX_CONF"
done

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
~/.tmux/plugins/tpm/bin/install_plugins

chsh -s $(which zsh)

exec zsh