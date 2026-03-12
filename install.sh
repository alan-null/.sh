#!/bin/bash

sudo -v

REPO_URL="https://github.com/alan-null/.sh.git"
INSTALL_DIR="$HOME/.sh"
BRANCH="${INSTALL_BRANCH:-master}"

echo "→ Installing .sh from $REPO_URL (branch: $BRANCH) to $INSTALL_DIR"

sudo apt update -y
sudo apt install -y curl git zsh fzf tmux

if [[ ! -d "$INSTALL_DIR" ]]; then
    git clone --depth=1 -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
else
    git -C "$INSTALL_DIR" pull --ff-only
fi

cd "$INSTALL_DIR" || exit

# oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    omz update
fi

# zsh theme
ln -sf "$INSTALL_DIR/themes/lambda-gitster.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/lambda-gitster.zsh-theme"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="lambda-gitster"/' "$HOME/.zshrc"

# zsh plugins
if ! grep -q "fzf" ~/.zshrc; then
    sed -i '/^plugins=/ s/)/ fzf)/' ~/.zshrc
fi

# zshrc
ZSHRC_CONF="$HOME/.zshrc"
touch "$ZSHRC_CONF"
line="[[ -f \"$HOME/.sh/.zshrc\" ]] && source \"$HOME/.sh/.zshrc\""
grep -qxF "$line" "$ZSHRC_CONF" || echo "$line" >> "$ZSHRC_CONF"

# tmux
ln -sf "$HOME/.sh/.tmux.conf" "$HOME/.tmux.conf"

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
~/.tmux/plugins/tpm/bin/install_plugins

sudo usermod -s $(which zsh) $USER

if [ -z "$ZSH_VERSION" ]; then
    exec bash "$INSTALL_DIR/includes/post_install.sh" "$INSTALL_DIR" "$ZSHRC_CONF"
fi
