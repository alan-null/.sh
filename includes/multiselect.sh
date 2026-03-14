#!/bin/bash

# Usage:
#   multiselect RESULT_VAR \
#     "Group A" "option1" "option2" \
#     "Group B" "option3"
#
# Groups are detected by lines ending with ":"
# After call, RESULT_VAR is an associative array: selected["option1"]=true/false

function multiselect() {
    local -n result=$1
    shift
    local raw=("$@")

    local options=()   # flat list of option names (no group headers)
    local groups=()    # group label per option index
    local render=()    # what to render per line: "group:Label" or "option:N"
    local selected=()

    # parse groups and options
    local current_group=""
    for item in "${raw[@]}"; do
        if [[ "$item" == *: ]]; then
            current_group="$item"
            render+=("group:$current_group")
        else
            local default=true
            local label="$item"
            if [[ "$item" == "~"* ]]; then
                default=false
                label="${item:1}"
            fi
            local idx=${#options[@]}
            options+=("$label")
            groups+=("$current_group")
            selected+=($default)
            result["$label"]=$default
            render+=("option:$idx")
        fi
    done

    local cursor=0  # cursor tracks option index, not render index
    local total_options=${#options[@]}
    local total_lines=${#render[@]}

    tput civis

    _draw_line() {
        local r=$1
        local entry="${render[$r]}"
        local type="${entry%%:*}"
        local val="${entry#*:}"

        tput el
        if [[ "$type" == "group" ]]; then
            echo -e " \e[1;37m${val}\e[0m"
        else
            local idx="$val"
            local checkbox="[ ]"
            [[ "${selected[$idx]}" == "true" ]] && checkbox="[x]"
            if [[ $idx == $cursor ]]; then
                echo -e " \e[1;36m▶ $checkbox ${options[$idx]}\e[0m"
            else
                echo -e "   $checkbox ${options[$idx]}"
            fi
        fi
    }

    draw() {
        for ((r=0; r<total_lines; r++)); do tput cuu1; done
        for ((r=0; r<total_lines; r++)); do
            _draw_line $r
        done
    }

    # initial render
    for ((r=0; r<total_lines; r++)); do
        _draw_line $r
    done

    while true; do
        # read directly from /dev/tty so arrow keys work when stdin is a pipe
        IFS= read -rsn1 key </dev/tty
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key </dev/tty
            case $key in
                '[A') ((cursor > 0)) && ((cursor--)) ;;
                '[B') ((cursor < total_options-1)) && ((cursor++)) ;;
            esac
        elif [[ $key == ' ' ]]; then
            if [[ "${selected[$cursor]}" == "true" ]]; then
                selected[$cursor]=false
            else
                selected[$cursor]=true
            fi
        elif [[ $key == '' ]]; then
            break
        fi
        draw
    done

    tput cnorm
    for ((i=0; i<total_options; i++)); do
        result["${options[$i]}"]="${selected[$i]}"
    done
}