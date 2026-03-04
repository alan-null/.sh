#!/bin/bash

sudo apt update -y
sudo apt install -y curl git zsh fzf tmux

REPO_URL="https://github.com/alan-null/.sh.git"
INSTALL_DIR="$HOME/.sh"

if [[ ! -d "$INSTALL_DIR" ]]; then
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
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

# git aliases (optional)
read -r -p "Install git aliases (gpl, gph, gc, gl, ...)? [y/N] " install_aliases
if [[ "$install_aliases" == "y" || "$install_aliases" == "Y" ]]; then
    alias_line="[[ -f \"$INSTALL_DIR/aliases/git-aliases.sh\" ]] && source \"$INSTALL_DIR/aliases/git-aliases.sh\""
    grep -qxF "$alias_line" "$ZSHRC_CONF" || echo "$alias_line" >> "$ZSHRC_CONF"
    echo "Git aliases installed."
fi

# tmux
ln -sf "$HOME/.sh/.tmux.conf" "$HOME/.tmux.conf"

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
~/.tmux/plugins/tpm/bin/install_plugins

chsh -s $(which zsh)

exec zsh