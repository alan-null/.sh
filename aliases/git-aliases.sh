# git aliases

alias gpl='git pull'
alias gph='git push'
alias gphf='git push --force'
alias gf='git fetch'
alias gm='git merge'
alias gcp='git cherry-pick'
alias grh='git reset --hard HEAD'
alias gr='git checkout -- .'
alias gl='git log --oneline --all --graph --decorate'

# override oh-my-zsh git plugin aliases
unalias gc gcm gb 2>/dev/null

function gc() { git checkout "$@" }
function gcm() { git checkout master }

function gb() {
  git branch "$@"
  git checkout "$@"
}
