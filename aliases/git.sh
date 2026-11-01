# git aliases

alias gs='git status -sb'
alias gph='git push'
alias gphf='git push --force'
alias gf='git fetch'
alias gm='git merge'
alias gcp='git cherry-pick'
alias grh='git reset --hard HEAD'
alias gr='git checkout -- .'
alias gl='git log --oneline --all --graph --decorate'

function gpl() {
  if (( $# == 0 )); then
    git pull
  else
    local dir
    for dir in "$@"; do
      echo "━━━ $dir ━━━"
      git -C "$dir" pull --ff-only || return 1
    done
  fi
}

# override oh-my-zsh git plugin aliases
unalias gc gcm gb 2>/dev/null

function gc() { git checkout "$@" }
function gcm() { git checkout master }

function gb() {
  git branch "$@"
  git checkout "$@"
}
