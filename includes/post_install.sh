#!/usr/bin/env bash

INSTALL_DIR="$1"
ZSHRC_CONF="$2"

# Unattended mode: SH_UNATTENDED=1 forces it, SH_UNATTENDED=0 disables it. By default it
# turns on when no terminal can be opened (Ansible, cron, CI).
if [[ -z ${SH_UNATTENDED:-} ]]; then
    if { : </dev/tty; } 2>/dev/null; then SH_UNATTENDED=0; else SH_UNATTENDED=1; fi
fi

# Interactive installs drop into the new shell; unattended ones just exit.
[[ $SH_UNATTENDED == 1 ]] || trap 'exec zsh' EXIT

# load modules
source "$INSTALL_DIR/includes/multiselect.sh"
source "$INSTALL_DIR/includes/install_git_aliases.sh"
source "$INSTALL_DIR/includes/install_terminal_aliases.sh"

# Component ids (used by SH_COMPONENTS) and their menu labels; "~" = off by default.
COMPONENT_IDS=(git-aliases terminal-aliases spotlight btop yazi)
declare -A COMPONENT_LABELS=(
    [git-aliases]="Git aliases (gpl, gph, gc, gl...)"
    [terminal-aliases]="Terminal aliases (cls, ..)"
    [spotlight]="Spotlight (command palette and file search)"
    [btop]="btop (modern top replacement)"
    [yazi]="~yazi (terminal file manager)"
)

declare -A choices
if [[ $SH_UNATTENDED == 1 ]]; then
    for id in "${COMPONENT_IDS[@]}"; do
        [[ ${COMPONENT_LABELS[$id]} == "~"* ]] && choices[$id]=false || choices[$id]=true
    done
    if [[ -n ${SH_COMPONENTS+x} ]]; then
        # Explicit comma-separated list replaces the defaults.
        for id in "${COMPONENT_IDS[@]}"; do choices[$id]=false; done
        IFS=',' read -ra wanted <<< "$SH_COMPONENTS"
        for id in "${wanted[@]}"; do
            id="${id// /}"
            [[ -z $id ]] && continue
            if [[ -z ${COMPONENT_LABELS[$id]+x} ]]; then
                printf 'Unknown component "%s" in SH_COMPONENTS (valid: %s)\n' "$id" "${COMPONENT_IDS[*]}" >&2
                exit 2
            fi
            choices[$id]=true
        done
    fi
    selected=()
    for id in "${COMPONENT_IDS[@]}"; do [[ ${choices[$id]} == true ]] && selected+=("$id"); done
    echo "→ Unattended install, components: ${selected[*]:-none}"
else
    # optional components — running under zsh, tty is quiet
    echo "Select optional components to install:"
    echo

    declare -A picked
    multiselect picked \
        "Aliases:" \
            "${COMPONENT_LABELS[git-aliases]}" \
            "${COMPONENT_LABELS[terminal-aliases]}" \
        "Packages:" \
            "${COMPONENT_LABELS[spotlight]}" \
            "${COMPONENT_LABELS[btop]}" \
            "${COMPONENT_LABELS[yazi]}" \

    echo
    for id in "${COMPONENT_IDS[@]}"; do
        choices[$id]="${picked["${COMPONENT_LABELS[$id]#\~}"]}"
    done
fi

status=0
if [[ ${choices[git-aliases]} == true ]]; then install_git_aliases "$INSTALL_DIR" "$ZSHRC_CONF" || status=1; fi
if [[ ${choices[terminal-aliases]} == true ]]; then install_terminal_aliases "$INSTALL_DIR" "$ZSHRC_CONF" || status=1; fi
if [[ ${choices[btop]} == true ]]; then
    { sudo apt install -y btop && echo "→ btop installed"; } || status=1
fi
if [[ ${choices[yazi]} == true ]]; then bash "$INSTALL_DIR/includes/install_yazi.sh" || status=1; fi
if [[ ${choices[spotlight]} == true ]]; then bash "$INSTALL_DIR/includes/install_spotlight.sh" || status=1; fi
exit "$status"
