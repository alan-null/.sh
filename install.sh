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

# load modules
source "$INSTALL_DIR/includes/multiselect.sh"
source "$INSTALL_DIR/includes/install_git_aliases.sh"
source "$INSTALL_DIR/includes/install_terminal_aliases.sh"
source "$INSTALL_DIR/includes/install_tmux_autostart.sh"

# optional components
echo "Select optional components to install:"
echo

declare -A choices
multiselect choices \
    "Aliases:" \
        "Git aliases (gpl, gph, gc, gl...)" \
        "Terminal aliases (cls, ..)" \
    "Packages:" \
        "btop (modern top replacement)" \
    "Tmux:" \
        "tmux autostart on SSH" \

echo
[[ "${choices["Git aliases (gpl, gph, gc, gl...)"]}" == "true" ]] && install_git_aliases "$INSTALL_DIR" "$ZSHRC_CONF"
[[ "${choices["Terminal aliases (cls, ..)"]}" == "true" ]] && install_terminal_aliases "$INSTALL_DIR" "$ZSHRC_CONF"
[[ "${choices["btop (modern top replacement)"]}" == "true" ]] && sudo -v && sudo apt install -y btop && echo "→ btop installed"
[[ "${choices["tmux autostart on SSH"]}" == "true" ]] && install_tmux_autostart "$ZSHRC_CONF"


# tmux
ln -sf "$HOME/.sh/.tmux.conf" "$HOME/.tmux.conf"

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
~/.tmux/plugins/tpm/bin/install_plugins

sudo usermod -s $(which zsh) $USER

exec zsh