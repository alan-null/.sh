export KEY_CMD_A=$'^A'
export KEY_LEFT=${terminfo[kcub1]:-$'^[[D'}
export KEY_RIGHT=${terminfo[kcuf1]:-$'^[[C'}

export KEY_SHIFT_LEFT=${terminfo[kLFT]:-$'^[[1;2D'}
export KEY_SHIFT_RIGHT=${terminfo[kRIT]:-$'^[[1;2C'}

export KEY_SHIFT_CTRL_LEFT=$'^[[1;6D'
export KEY_SHIFT_CTRL_RIGHT=$'^[[1;6C'

r-select() {
  ((REGION_ACTIVE)) || zle set-mark-command
  local widget_name=$1
  shift
  zle $widget_name -- $@
}

r-deselect() {
  ((REGION_ACTIVE = 0))
  local widget_name=$1
  shift
  zle $widget_name -- $@
}

r-select-all() {
  zle beginning-of-line
  zle set-mark-command
  zle end-of-line
}

for key               seq                     mode            widget (
    all               $KEY_CMD_A              select-all      -

    left              $KEY_LEFT               deselect        backward-char
    right             $KEY_RIGHT              deselect        forward-char

    shift-left        $KEY_SHIFT_LEFT         select          backward-char
    shift-right       $KEY_SHIFT_RIGHT        select          forward-char
  )
{
  eval "key-$key() {
    r-$mode $widget \$@
  }"
  zle -N key-$key
  bindkey $seq key-$key
}