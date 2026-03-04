local ret_status="%(?:%{$fg_bold[green]%}λ :%{$fg_bold[red]%}λ %s)"

function get_pwd(){
  git_root=$PWD
  while [[ $git_root != / && ! -e $git_root/.git ]]; do
    git_root=$git_root:h
  done
  if [[ $git_root = / ]]; then
    unset git_root
    prompt_short_dir=%~
  else
    parent=${git_root%\/*}
    prompt_short_dir=${PWD#$parent/}
  fi
  echo $prompt_short_dir
}

function git_extra_info() {
  # Must be inside a git repo
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local info=""

  # Staged files (index)
  local staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  if [[ $staged -gt 0 ]]; then
    info+=" %{$fg[green]%}●${staged}%{$reset_color%}"
  fi


  # Ahead/behind remote
  local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [[ -n $upstream ]]; then
    local ahead=$(git_commits_ahead 2>/dev/null)
    local behind=$(git_commits_behind 2>/dev/null)
    # local ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    # local behind=$(git rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ')
    [[ $ahead -gt 0 ]]  && info+=" %{$fg[yellow]%}⇡${ahead}%{$reset_color%}"
    [[ $behind -gt 0 ]] && info+=" %{$fg[cyan]%}⇣${behind}%{$reset_color%}"
  fi

  # Stashes
  local stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  if [[ $stashes -gt 0 ]]; then
    info+=" %{$fg[magenta]%}◉ %{$reset_color%}"
    # info+=" %{$fg[magenta]%}⚑${stashes}%{$reset_color%}"
  fi
  echo $info
}

PROMPT='$ret_status %{$fg[white]%}$(get_pwd) $(git_prompt_info)$(git_extra_info)%{$reset_color%} '
# PROMPT='$ret_status %{$fg[white]%}$(get_pwd) $(git_prompt_info)$(git_prompt_status)%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✓%{$reset_color%}"


# ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}+"       # staged new file
# ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}~"   # staged modification
# ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}-"        # staged deletion
# ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}>"   # staged rename
# ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}="       # merge conflict
# ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[white]%}?"   # untracked files

# https://github.com/ergenekonyigit/lambda-gitster