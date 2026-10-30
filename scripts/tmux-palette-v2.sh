#!/usr/bin/env bash
set -u

# tmux command palette. Requires fzf and tmux >= 3.2.

preview() {
  case "${1:-}" in
    new-window) printf 'WINDOWS\n\nCreate a new window in the current session.\n\ntmux new-window\n' ;;
    rename-window) printf 'WINDOWS\n\nRename the currently selected window.\n\ntmux command-prompt ... rename-window\n' ;;
    next-window) printf 'WINDOWS\n\nSwitch to the next window.\n\ntmux next-window\n' ;;
    previous-window) printf 'WINDOWS\n\nSwitch to the previous window.\n\ntmux previous-window\n' ;;
    close-window) printf 'WINDOWS\n\nAsk for confirmation before closing the window and its panes.\n' ;;
    split-right) printf 'PANES\n\nCreate a new pane to the right.\n\ntmux split-window -h\n' ;;
    split-down) printf 'PANES\n\nCreate a new pane below.\n\ntmux split-window -v\n' ;;
    zoom-pane) printf 'PANES\n\nToggle maximizing the active pane.\n\ntmux resize-pane -Z\n' ;;
    swap-pane) printf 'PANES\n\nSwap active pane with the next pane.\n\ntmux swap-pane -D\n' ;;
    close-pane) printf 'PANES\n\nAsk for confirmation before closing the active pane.\n' ;;
    session-browser) printf 'SESSIONS\n\nBrowse sessions, windows, and panes using tmux tree mode.\n' ;;
    rename-session) printf 'SESSIONS\n\nPrompt for a new session name.\n' ;;
    detach) printf 'SESSIONS\n\nDisconnect this tmux client. Your running programs stay alive.\n' ;;
    copy-mode) printf 'NAVIGATION\n\nEnter tmux copy mode to scroll/search history.\n' ;;
    paste-buffer) printf 'CLIPBOARD\n\nPaste the most recent tmux paste buffer into the active pane.\n\nThis is not necessarily your system clipboard.\n' ;;
    buffer-list) printf 'CLIPBOARD\n\nSelect a tmux paste buffer.\n' ;;
    reload-config) printf 'CONFIGURATION\n\nReload ~/.tmux.conf without restarting tmux.\n' ;;
    keybindings) printf 'CONFIGURATION\n\nShow tmux keybindings in a scrollable list.\n' ;;
    save-session) printf 'PERSISTENCE\n\nSave the session using tmux-resurrect.\n\nRequires the tmux-resurrect plugin.\n' ;;
    restore-session) printf 'PERSISTENCE\n\nRestore the saved session using tmux-resurrect.\n\nRequires the tmux-resurrect plugin.\n' ;;
  esac
}

if [[ "${1:-}" == '--preview' ]]; then
  preview "${2:-}"
  exit 0
fi

if [[ -z "${TMUX:-}" ]]; then
  echo 'Run this palette inside tmux.' >&2
  exit 1
fi
if ! command -v fzf >/dev/null; then
  echo 'fzf is required. Install it first.' >&2
  exit 1
fi

# Each visible row is a single searchable field; the hidden action ID is after a tab.
# This avoids fzf --nth filtering out the command name.
commands() {
  add() {
    local id="$1" name="$2" category="$3" shortcut="$4" tint
    case "$category" in
      WINDOWS)       tint='\033[38;5;81m' ;;
      PANES)         tint='\033[38;5;114m' ;;
      SESSIONS)      tint='\033[38;5;221m' ;;
      NAVIGATION)    tint='\033[38;5;177m' ;;
      CLIPBOARD)     tint='\033[38;5;216m' ;;
      CONFIGURATION) tint='\033[38;5;110m' ;;
      PERSISTENCE)   tint='\033[38;5;150m' ;;
      *)             tint='' ;;
    esac
    local reset='\033[0m' muted='\033[38;5;245m'
    # Printable text is padded BEFORE applying ANSI codes, so columns stay aligned.
    local namecol catcol hintcol
    printf -v namecol '%-27s' "$name"
    printf -v catcol '%-15s' "$category"
    printf -v hintcol '%s' "$shortcut"
    printf '%b\t%s\n' "  ${namecol}  ${tint}${catcol}${reset}  ${muted}${hintcol}${reset}" "$id"
  }

  add new-window       'New window'            'WINDOWS'       'prefix c'
  add rename-window    'Rename window'         'WINDOWS'       'prefix ,'
  add next-window      'Next window'           'WINDOWS'       'prefix n'
  add previous-window  'Previous window'       'WINDOWS'       'prefix p'
  add close-window     'Close window...'       'WINDOWS'       ''
  add split-right      'Split right'           'PANES'         'prefix %'
  add split-down       'Split below'           'PANES'         'prefix "'
  add zoom-pane        'Zoom / unzoom pane'    'PANES'         'prefix z'
  add swap-pane        'Swap with next pane'   'PANES'         ''
  add close-pane       'Close pane...'         'PANES'         'prefix x'
  add session-browser  'Browse sessions'       'SESSIONS'      'prefix s'
  add rename-session   'Rename session'        'SESSIONS'      'prefix $'
  add detach           'Detach client'         'SESSIONS'      'prefix d'
  add copy-mode        'Enter copy mode'       'NAVIGATION'    'prefix ['
  add paste-buffer     'Paste tmux buffer'     'CLIPBOARD'     'prefix ]'
  add buffer-list      'Browse tmux buffers'   'CLIPBOARD'     ''
  add reload-config    'Reload configuration'  'CONFIGURATION' ''
  add keybindings      'Show keybindings'      'CONFIGURATION' 'prefix ?'

  if [[ -f "${HOME}/.tmux/plugins/tmux-resurrect/scripts/save.sh" ]]; then
    add save-session    'Save session'          'PERSISTENCE'   'prefix Ctrl+s'
    add restore-session 'Restore session'      'PERSISTENCE'   'prefix Ctrl+r'
  fi
}

selected=$(commands | fzf \
  --ansi \
  --delimiter=$'\t' \
  --with-nth=1 \
  --nth=1 \
  --layout=reverse \
  --border=none \
  --prompt='  Search ❯ ' \
  --pointer='▸' \
  --marker='✓' \
  --info=inline-right \
  --header='  COMMAND                             CATEGORY          SHORTCUT   •   Enter run   •   Ctrl+/ preview' \
  --header-first \
  --preview="$(printf '%q' "$0") --preview {2}" \
  --preview-window='right:40%:wrap:border-left' \
  --bind='ctrl-/:toggle-preview' \
  --color='bg:#161b22,bg+:#283747,fg:#d5dce4,fg+:#ffffff,hl:#7dd3a8,hl+:#7dd3a8,header:#8093a8,prompt:#7dd3a8,pointer:#7dd3a8,border:#485463,info:#8093a8' \
) || exit 0

# The second tab-separated field is a stable internal ID (not shown or searched).
id="${selected##*$'\t'}"

case "$id" in
  new-window)      tmux new-window ;;
  rename-window)   tmux command-prompt -I '#W' 'rename-window -- "%%"' ;;
  next-window)     tmux next-window ;;
  previous-window) tmux previous-window ;;
  close-window)    tmux confirm-before -p 'Close current window? (y/n)' 'kill-window' ;;
  split-right)     tmux split-window -h ;;
  split-down)      tmux split-window -v ;;
  zoom-pane)       tmux resize-pane -Z ;;
  swap-pane)       tmux swap-pane -D ;;
  close-pane)      tmux confirm-before -p 'Close current pane? (y/n)' 'kill-pane' ;;
  session-browser) tmux choose-tree -s ;;
  rename-session)  tmux command-prompt -I '#S' 'rename-session -- "%%"' ;;
  detach)          tmux detach-client ;;
  copy-mode)       tmux copy-mode ;;
  paste-buffer)    tmux paste-buffer ;;
  buffer-list)     tmux choose-buffer ;;
  reload-config)   tmux source-file "$HOME/.tmux.conf" && tmux display-message 'tmux configuration reloaded' ;;
  keybindings)     tmux list-keys | less -R ;;
  save-session)    tmux run-shell -b "$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh" ;;
  restore-session) tmux run-shell -b "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh" ;;
esac
