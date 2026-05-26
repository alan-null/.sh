#!/bin/bash

REPO_URL="https://github.com/alan-null/.sh.git"
INSTALL_DIR="$HOME/.sh"
BRANCH="${INSTALL_BRANCH:-master}"

IS_TERMUX=false
if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == *"com.termux"* ]] || [[ -d "/data/data/com.termux/files/usr" ]]; then
    IS_TERMUX=true
fi

install_packages() {
    if [[ "$IS_TERMUX" == "true" ]]; then
        pkg update -y
        pkg install -y curl git zsh fzf tmux
    else
        sudo apt update -y
        sudo apt install -y curl git zsh fzf tmux
    fi
}

echo "→ Installing .sh from $REPO_URL (branch: $BRANCH) to $INSTALL_DIR"
install_packages

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
    git -C "$HOME/.oh-my-zsh" pull --ff-only
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

if [[ "$IS_TERMUX" == "true" ]]; then
    if command -v chsh >/dev/null 2>&1; then
        chsh -s "$(command -v zsh)"
    else
        echo "→ Skipping default shell switch (chsh not available in this Termux setup)"
    fi
else
    sudo usermod -s "$(which zsh)" "$USER"
fi

if [ -z "$ZSH_VERSION" ]; then
    exec bash "$INSTALL_DIR/includes/post_install.sh" "$INSTALL_DIR" "$ZSHRC_CONF"
fi
