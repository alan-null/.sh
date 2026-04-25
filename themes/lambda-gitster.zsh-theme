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

PROMPT='$ret_status %{$fg[white]%}$(get_pwd) $(git_prompt_info)$(git_prompt_status)$(git_commits_ahead)$(git_commits_behind)%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✓%{$reset_color%}"

# File status indicators (used by git_prompt_status)
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}+"                    # staged new file
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}~"                # staged modification
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}-"                    # staged deletion
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}>"                # staged rename
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}="                   # merge conflict
ZSH_THEME_GIT_PROMPT_UNTRACKED=""                               # untracked (shown via dirty flag already)
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}◉"                   # stashed changes

# Remote tracking status (used by git_commits_ahead/behind)
ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX=" %{$fg_bold[green]%}↑"
ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX="%{$reset_color%}"           # need to push
ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX=" %{$fg_bold[red]%}↓"
ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX="%{$reset_color%}"          # need to pull

# https://github.com/ergenekonyigit/lambda-gitster