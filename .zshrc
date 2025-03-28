# KEYS
export KEY_ESC=$'^['

export KEY_LEFT=${terminfo[kcub1]:-$'^[[D'}
export KEY_RIGHT=${terminfo[kcuf1]:-$'^[[C'}
export KEY_HOME=${terminfo[khome]:-$'^[[H'}
export KEY_END=${terminfo[kend]:-$'^[[F'}
export KEY_BACKSPACE=$'^?'
export KEY_DELETE=${terminfo[kdch1]:-$'^[[3~'}

export KEY_CMD_A=$'^A'
export KEY_CMD_Z=$'^Z'
export KEY_CMD_Y=$'^Y'
export KEY_CMD_LEFT=$'^[[1;5D'
export KEY_CMD_RIGHT=$'^[[1;5C'

export KEY_SHIFT_LEFT=${terminfo[kLFT]:-$'^[[1;2D'}
export KEY_SHIFT_RIGHT=${terminfo[kRIT]:-$'^[[1;2C'}
export KEY_SHIFT_UP=${terminfo[sup]:-$'^[[1;2A'}
export KEY_SHIFT_DOWN=${terminfo[sdown]:-$'^[[1;2B'}
export KEY_SHIFT_HOME=${terminfo[kHOM]:-$'^[[1;2H'}
export KEY_SHIFT_END=${terminfo[kEND]:-$'^[[1;2F'}

export KEY_SHIFT_CMD_LEFT=$'^[[1;6D'
export KEY_SHIFT_CMD_RIGHT=$'^[[1;6C'

# WIDGETS
zle -N widget::select-all
widget::select-all() {
  zle beginning-of-line
  zle set-mark-command
  zle end-of-line
}

widget::select() {
  ((REGION_ACTIVE)) || zle set-mark-command
  local widget_name=$1
  shift
  zle $widget_name -- $@
}

widget::deselect() {
  ((REGION_ACTIVE = 0))
  local widget_name=$1
  shift
  zle $widget_name -- $@
}

widget::delete(){
  if ((REGION_ACTIVE)) then
     zle kill-region
  else
    local widget_name=$1
    shift
    zle $widget_name -- $@
  fi
}

# BINDINGS
bindkey               $KEY_CMD_Y              redo
bindkey               $KEY_CMD_Z              undo
bindkey               $KEY_CMD_A              widget::select-all

for key               seq                     mode            widget (
    esc               $KEY_ESC                deselect        vi-insert

    left              $KEY_LEFT               deselect        backward-char
    right             $KEY_RIGHT              deselect        forward-char

    ctrl-left         $KEY_CMD_LEFT           deselect        backward-word
    ctrl-right        $KEY_CMD_RIGHT          deselect        forward-word

    end               $KEY_END                deselect        end-of-line
    home              $KEY_HOME               deselect        beginning-of-line

    shift-left        $KEY_SHIFT_LEFT         select          backward-char
    shift-right       $KEY_SHIFT_RIGHT        select          forward-char
    shift-up          $KEY_SHIFT_UP           select          up-line-or-history
    shift-down        $KEY_SHIFT_DOWN         select          down-line-or-history

    shift-home        $KEY_SHIFT_HOME         select          beginning-of-line
    shift-end         $KEY_SHIFT_END          select          end-of-line

    ctrl-shift-left   $KEY_SHIFT_CMD_LEFT     select          backward-word
    ctrl-shift-right  $KEY_SHIFT_CMD_RIGHT    select          forward-word

    delete            $KEY_DELETE             delete          delete-char
    backspace         $KEY_BACKSPACE          delete          backward-delete-char
  )
{
  eval "key-$key() {
    widget::$mode $widget \$@
  }"
  zle -N key-$key
  bindkey $seq key-$key
}