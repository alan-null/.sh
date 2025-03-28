#!/bin/bash

sudo apt update -y
sudo apt install -y curl git zsh fzf tmux

REPO_URL="https://github.com/alan-null/.sh.git"
INSTALL_DIR="$HOME/.linux-setup"

if [[ ! -d "$INSTALL_DIR" ]]; then
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR" || exit

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
ln -sf "$HOME/.linux-setup/.tmux.conf" "$HOME/.tmux.conf"

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
~/.tmux/plugins/tpm/bin/install_plugins

chsh -s $(which zsh)

exec zsh