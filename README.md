# .sh
Linux setup script

## Usage

One liner install:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/master/install.sh)
```

### Unattended install

The optional-components menu is skipped when no terminal is available (Ansible, cron, CI), or when `SH_UNATTENDED=1` is set; `SH_UNATTENDED=0` forces the menu. Unattended installs use the menu defaults unless `SH_COMPONENTS` lists the components to install, comma-separated: `git-aliases`, `terminal-aliases`, `spotlight`, `btop`, `yazi`. An empty value installs none, and an unknown id stops the install. The installer exits non-zero if a selected component fails and does not start Zsh at the end. `sudo` must not prompt for a password.

```bash
SH_UNATTENDED=1 SH_COMPONENTS=git-aliases,terminal-aliases,spotlight,btop \
  bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/master/install.sh)
```

## Updates

Run `sh-update` after loading this repository's Zsh configuration, or run `bash ~/.sh/update.sh` from any directory. The updater fast-forwards the current branch from its configured upstream, then checks out already initialized recursive submodules at the commits recorded by that branch.

Local changes, a detached checkout, a missing upstream, or diverging history stop the update. If a submodule download fails after the shell repository updates, resolve the failure and rerun the command.

Submodules use this repository's pinned commits. Adopting a newer dependency requires updating its submodule reference here. Oh My Zsh, tmux plugins, and system packages use their own update mechanisms. Reload the shell configuration after updating, and reload tmux configuration when bindings change.

## Spotlight

[Spotlight](https://github.com/alan-null/spotlight) is included as a Git submodule under [spotlight/](spotlight/). Select it in the installer’s optional-components menu (selected by default, like btop). Skipping it leaves Spotlight and its shortcuts disabled, and updates keep it skipped. To install it later, run `bash ~/.sh/includes/install_spotlight.sh`, then reload Zsh and tmux.

Press `Ctrl+Space` for Commands or `Ctrl+P` for Files. In Zsh, selections are inserted at the current cursor. Inside tmux, Spotlight opens in a popup and adds navigation for windows, sessions, and panes. Enter selects, Escape closes, Left/Right changes tabs, `Ctrl+/` toggles the preview, and `Ctrl+R` refreshes the active tab. Commands are inserted without pressing Enter; built-in tmux operations run when selected.

Spotlight requires Python 3.11+, Bash, and fzf; tmux popups require tmux 3.2+. When Spotlight is selected, the installer installs Python and checks its version. Personal settings, actions, modules, and themes remain in the user's XDG configuration directories. See the [Spotlight guide](spotlight/README.md) and [module documentation](spotlight/MODULES.md).

Reload Zsh with `source ~/.sh/.zshrc` and tmux with `tmux source-file ~/.tmux.conf` after changing bindings. A running tmux server keeps its old bindings until reloaded or restarted, even after updating `~/.sh`; if `Ctrl+Space` opens full-screen Spotlight inside tmux instead of a popup, Zsh received the key because tmux has no Spotlight binding yet (check with `tmux list-keys -T root | grep spotlight`). The terminal must pass the configured shortcuts through to Zsh or tmux.

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
