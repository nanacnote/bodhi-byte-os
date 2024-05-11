#!/bin/sh

SCRIPT_NAME=$(basename "$0")

apply_symlinks() {
    ln -sfv ${PWD}/dotfiles/config/.zshenv ~/.zshenv
    ln -sfv ${PWD}/dotfiles/config/.zshrc ~/.zshrc
    ln -sfv ${PWD}/dotfiles/config/.xinitrc ~/.xinitrc
    ln -sfv ${PWD}/dotfiles/config/.vimrc ~/.vimrc
    ln -sfv ${PWD}/dotfiles/config/.gitconfig ~/.gitconfig
    ln -sfv ${PWD}/dotfiles/config/.ssh-config ~/.ssh/config

    sudo ln -sfv ${PWD}/dotfiles/script/on-login-script.sh /etc/profile.d/on-login-script.sh
}

install_dwm() {
    cd dwm || exit
    sudo make clean install
}

rebuild_dwm() {
    cd dwm || exit
    sudo make clean install
}

install_dwmblocks() {
    cd dwmblocks || exit
    sudo make clean install
}

rebuild_dwmblocks() {
    cd dwmblocks || exit
    sudo make clean install
}

install_st() {
    cd st || exit
    sudo make clean install
}

rebuild_st() {
    cd st || exit
    sudo make clean install
}

show_help() {
    cat <<-EOF
    Usage: $SCRIPT_NAME <command> [options]

    Commands:
      apply-symlinks      Apply symlinks for configs and scripts.
      install-dwm         Install dwm.
      rebuild-dwm         Rebuild and reinstall dwm when config is updated.
      install-dwmblocks   Install dwmblocks.
      rebuild-dwmblocks   Rebuild and reinstall dwmblocks when config is updated.
      install-st          Install st.
      rebuild-st          Rebuild and reinstall st when config is updated.
      help                Show this help message.
EOF
}

case "$1" in
    apply-symlinks)
        apply_symlinks
        ;;
    install-dwm)
        install_dwm
        ;;
    rebuild-dwm)
        rebuild_dwm
        ;;
    install-dwmblocks)
        install_dwmblocks
        ;;
    rebuild-dwmblocks)
        rebuild_dwmblocks
        ;;
    install-st)
        install_st
        ;;
    rebuild-st)
        rebuild_st
        ;;
    help | *)
        show_help
        ;;
esac
