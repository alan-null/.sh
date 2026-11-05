# .sh
Linux setup script

## Usage

One liner install:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/master/install.sh)
```


## Spotlight

[Spotlight](https://github.com/alan-null/spotlight) is included as a Git submodule under [spotlight/](spotlight/). The installer initializes it automatically. After cloning this repository manually, run `git submodule update --init --recursive` before opening Spotlight.

Press `Ctrl+Space` for Commands or `Ctrl+P` for Files. In Zsh, selections are inserted at the current cursor. Inside tmux, Spotlight opens in a popup and adds navigation for windows, sessions, and panes. Enter selects, Escape closes, Left/Right changes tabs, `Ctrl+/` toggles the preview, and `Ctrl+R` refreshes the active tab. Commands are inserted without pressing Enter; built-in tmux operations run when selected.

Spotlight requires Python 3.11+, Bash, and fzf; tmux popups require tmux 3.2+. The installer installs Python and checks its version. Personal settings, actions, modules, and themes remain in the user's XDG configuration directories. See the [Spotlight guide](spotlight/README.md) and [module documentation](spotlight/MODULES.md).

Reload Zsh with `source ~/.sh/.zshrc` and tmux with `tmux source-file ~/.tmux.conf` after changing bindings. The terminal must pass the configured shortcuts through to Zsh or tmux.

## Development

#### reload tmux config
```bash
tmux source-file ~/.tmux.conf
```

#### Install from branch

```bash
export INSTALL_BRANCH=wip/multiselect
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/wip/multiselect/install.sh)
```
