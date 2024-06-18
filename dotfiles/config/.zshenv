# aliases
alias nv='nvim'
alias rm='rm -i'
alias ls='eza --color=auto'
alias la='eza -la --color=auto'
alias cat='bat'
alias pacman='paru'
alias grep='grep --color=auto'
alias hist='history 1'
alias ff='fzf --bind "enter:become(vim {} || exit 0)" --preview "bat --color=always --style=numbers --line-range=:100 {}"'
alias fd='cd $(find "$HOME" -type d | fzf --height 10 --layout=reverse --border --exit-0 || echo "$PWD")'

