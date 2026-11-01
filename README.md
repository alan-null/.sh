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

Press `Ctrl+Space` to open the command center on Commands, or `Ctrl+P` to open it on Files. Use Left/Right to switch between Commands, Windows, Sessions, Panes, and Files. Enter selects an item, Esc closes the launcher, `Ctrl+/` toggles the preview, and `Ctrl+R` refreshes the active tab. Each tab keeps its own search query until the launcher closes.

Add frequently used shell commands to [scripts/tmux-commands.tsv](scripts/tmux-commands.tsv). Each line has four tab-separated fields: `name`, `category`, `description`, and `snippet`. The name, category, and description are searchable; the preview shows the full snippet. Selecting a snippet inserts it at the current shell cursor without running it. Use actual tabs between fields and keep each snippet on one line. Built-in tmux actions still run when selected. Snippets are cached in the tmux server after the first load; press `Ctrl+R` on Commands to load edits from the file.

Ctrl+Tab opens the tmux pane and window switcher when the terminal passes that key to tmux. In Konsole, this requires a Ctrl+Tab keyboard rule and clearing Konsole's own Next Tab shortcut. Ctrl+B, then Tab opens the switcher as a fallback.

#### Install from branch

```bash
export INSTALL_BRANCH=wip/multiselect
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/wip/multiselect/install.sh)
```
