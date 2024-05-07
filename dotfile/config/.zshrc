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


#####################
#       CUSTOM      #
#####################

# --- Share history across sessions and terminals ---
HISTDUP=erase               # Erase duplicates from history
setopt  appendhistory       # Append history (not overwriting)
setopt  sharehistory        # Share history across terminals 
setopt  incappendhistory    # Immediately append to history (no waiting till after session)

# --- plugins ---
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# --- Set PS1 customisation via oh-my-posh ---
eval "$(oh-my-posh init zsh --config ~/.cache/oh-my-posh/themes/gruvbox.omp.json)"