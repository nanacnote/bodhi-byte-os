# aliases
alias rm='rm -i'
alias cat='bat'
alias pacman='paru'
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias la='ls -la --color=auto'
alias hist='history 1'
alias ff='fzf --bind "enter:become(vim {} || exit 0)" --preview "bat --color=always --style=numbers --line-range=:100 {}"'

