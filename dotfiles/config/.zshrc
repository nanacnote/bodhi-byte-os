# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/nana/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall


bindkey ';5C' forward-word   # ctrl+-> partial(word) select suggestion 
bindkey ';5D' backward-word   # ctrl+<- partial(word) reverse suggestion 

#####################
#       CUSTOM      #
#####################

# --- Share history across sessions and terminals ---
HISTDUP=erase               # Erase duplicates from history
HISTCONTROL=ignoreboth      # Lines beginning with space are not saved
setopt  appendhistory       # Append history (not overwriting)
setopt  sharehistory        # Share history across terminals 
setopt  incappendhistory    # Immediately append to history (no waiting till after session)

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

