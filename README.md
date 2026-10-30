# .sh
Linux setup script

## Usage

One liner install:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/master/install.sh)
```

## Development

#### reload tmux config
```bash
tmux source-file ~/.tmux.conf
```

#### tmux command center

Press `Ctrl+P` to open the command center. Use Left/Right to switch between
Commands, Windows, Sessions, and Panes; Enter runs a command or switches to the
selected target, including targets in other sessions. Esc closes the launcher.
`Ctrl+/` toggles the preview; `Ctrl+B` / `Ctrl+F` move the search cursor.

Commands is always the initial tab. Other tabs load only when first opened,
and their results are cached for that launcher invocation. `Ctrl+R` refreshes
only the active tab. Each tab retains its own search query. No filesystem
search runs, and reopening the launcher starts with fresh results.

#### Install from branch

```bash
export INSTALL_BRANCH=wip/multiselect
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/wip/multiselect/install.sh)
```
