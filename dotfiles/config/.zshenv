# aliases
alias nv='nvim'
alias rm='rm -i'
alias ls='eza --color=auto'
alias la='eza -la --color=auto'
alias cat='bat'
alias pacman='paru'
alias grep='grep --color=auto'
alias hist='history 1'
alias ffnv='fzf --bind "enter:become(nvim {} || exit 0)" --preview "bat --color=always --style=numbers --line-range=:100 {}"'
alias ff='fzf --height 15 --layout=reverse --border --bind "enter:become(bat {} || exit 0)"'
alias fd='cd $(find "$HOME" -type d | fzf --height 15 --layout=reverse --border --exit-0 || echo "$PWD")'

