zstyle :compinstall filename '/home/nana/.zshrc'

autoload -Uz compinit
compinit



# --- key bindings ---
bindkey '^[[1;5C' forward-word          # ctrl+right arrow - forward by one word
bindkey '^[[1;5D' backward-word         # ctrl+left arrow - backward by one word
bindkey '^[[1;5A' history-search-forward # ctrl+up arrow - search forward for matching command with respect to first word in current buffer
bindkey '^[[1;5B' history-search-backward # ctrl+down arrow - search backward for matching command with respect to first word in current buffer



# --- options ---
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
HISTDUP=erase               # Erase duplicates from history
HISTCONTROL=ignoreboth      # Lines beginning with space are not saved
setopt  appendhistory       # Append history (not overwriting)
setopt  sharehistory        # Share history across terminals 
setopt  incappendhistory    # Immediately append to history (no waiting till after session)
setopt  autocd              # Change directory without cd



# --- hooks ---
zsh-hook-no-failed-cmd-in-history(){ [[ $? -ne 0 ]] && sed -i '$d' "$HISTFILE" }   # remove failed commands from history
autoload -Uz add-zsh-hook
add-zsh-hook precmd zsh-hook-no-failed-cmd-in-history



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

