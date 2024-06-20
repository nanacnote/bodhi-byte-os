zstyle :compinstall filename '/home/nana/.zshrc'
zstyle ':completion:*' menu select

autoload -Uz compinit && compinit
autoload -Uz colors && colors



# --- key bindings ---
bindkey '^[[1;5C' forward-word              # ctrl+right arrow - forward by one word
bindkey '^[[1;5D' backward-word             # ctrl+left arrow - backward by one word
bindkey '^[[1;5A' history-search-forward    # ctrl+up arrow - search forward for matching command with respect to first word in current buffer
bindkey '^[[1;5B' history-search-backward   # ctrl+down arrow - search backward for matching command with respect to first word in current buffer



# --- options ---
# https://zsh.sourceforge.io/Doc/Release/Options.html#Description-of-Options
HISTFILE=~/.histfile
HISTSIZE=2000
SAVEHIST=2000                   # History should be saved to HISTFILE always
HISTORY_IGNORE="(ls|ls *|cd|cd *|cat|cat *|eza|eza *|rm|rm *|man|man *|bat|bat *|pwd|exit|clear|)"
HISTORY_IGNORE="${HISTORY_IGNORE}(nvim *|nv *|vim *|)"
setopt  APPEND_HISTORY
setopt  INC_APPEND_HISTORY
setopt  HIST_IGNORE_ALL_DUPS
setopt  HIST_IGNORE_DUPS
setopt  HIST_SAVE_NO_DUPS
setopt  HIST_IGNORE_SPACE
setopt  HIST_EXPIRE_DUPS_FIRST
setopt  HIST_REDUCE_BLANKS
setopt  HIST_VERIFY

setopt  AUTO_CD                 # Change directory without cd



# --- set cursor according to mode ---
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
zle-keymap-select() {
    if [[ $KEYMAP == vicmd ]]; then
        echo -ne "\e[2 q"
    else
        echo -ne "\e[6 q"
    fi
    zle reset-prompt
    zle -R
}
zle-line-init() { echo -ne "\e[6 q" }
zle -N zle-keymap-select
zle -N zle-line-init



# --- hooks ---
# https://zsh.sourceforge.io/Doc/Release/Functions.html
zsh-hook-no-failed-cmd-in-history(){ [[ $? -ne 0 ]] && sed -i '$d' "$HISTFILE" }        # remove failed commands from history
zsh-hook-set-block-cursor(){ echo -ne "\e[2 q" }                                        # set the cursor to block before exec a cmd
autoload -Uz add-zsh-hook
add-zsh-hook precmd zsh-hook-no-failed-cmd-in-history
add-zsh-hook preexec zsh-hook-set-block-cursor



# --- plugins ---
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh



# --- Set PS1 customisation via oh-my-posh ---
eval "$(oh-my-posh init zsh --config ~/.cache/oh-my-posh/themes/custom-gruvbox.omp.json)"



# --- nvm ---
export NVM_DIR="${HOME}/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"



# --- pyenv ---
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"



# --- sdkman ---
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"



# --- source completion script ---
source ~/.config/bodhi-byte-os/utils/completions.zsh
