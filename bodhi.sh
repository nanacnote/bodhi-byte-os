#!/bin/sh

SCRIPT_NAME=$(basename "$0")
BODHI_ROOT=$(dirname "$(realpath "$0")")

# TODO:
# - command to list utils
# - add auto complete

apply_symlinks() {
    sudo ln -sfv ${BODHI_ROOT}/bodhi.sh /usr/local/bin/bodhi
    sudo ln -sfv ${BODHI_ROOT}/utils/custom-dmenu-run.sh /usr/local/bin/custom-dmenu-run
    sudo ln -sfv ${BODHI_ROOT}/utils/groqai.sh /usr/local/bin/groqai


    ln -sfv ${BODHI_ROOT}/dotfiles/config/.zshenv ~/.zshenv
    ln -sfv ${BODHI_ROOT}/dotfiles/config/.zshrc ~/.zshrc
    ln -sfv ${BODHI_ROOT}/dotfiles/config/.xinitrc ~/.xinitrc
    ln -sfv ${BODHI_ROOT}/dotfiles/config/.Xmodmap ~/.Xmodmap
    ln -sfv ${BODHI_ROOT}/dotfiles/config/.vimrc ~/.vimrc
    ln -sfv ${BODHI_ROOT}/dotfiles/config/.gitconfig ~/.gitconfig
    ln -sfv ${BODHI_ROOT}/dotfiles/config/.ssh-config ~/.ssh/config
    ln -sfv ${BODHI_ROOT}/dotfiles/config/picom.conf ~/.config/picom/picom.conf


    sudo ln -sfv ${BODHI_ROOT}/dotfiles/config/custom-gruvbox.omp.json ~/.cache/oh-my-posh/themes/custom-gruvbox.omp.json
    sudo ln -sfv ${BODHI_ROOT}/dotfiles/script/on-login-script.sh /etc/profile.d/on-login-script.sh
}

install_dwm() {
    cd ${BODHI_ROOT}/dwm || exit
    sudo make clean install
}
rebuild_dwm() {
    cd ${BODHI_ROOT}/dwm || exit
    sudo make clean install
}

install_st() {
    cd ${BODHI_ROOT}/st || exit
    sudo make clean install
}
rebuild_st() {
    cd ${BODHI_ROOT}/st || exit
    sudo make clean install
}

install_dmenu() {
    cd ${BODHI_ROOT}/dmenu || exit
    sudo make clean install
}
rebuild_dmenu() {
    cd ${BODHI_ROOT}/dmenu || exit
    sudo make clean install
}

install_slock() {
    cd ${BODHI_ROOT}/slock || exit
    sudo make clean install
}
rebuild_slock() {
    cd ${BODHI_ROOT}/slock || exit
    sudo make clean install
}

install_dwmblocks() {
    cd ${BODHI_ROOT}/dwmblocks || exit
    sudo make clean install
}
rebuild_dwmblocks() {
    cd ${BODHI_ROOT}/dwmblocks || exit
    sudo make clean install
}

show_help() {
    cat <<-EOF
    Usage: $SCRIPT_NAME <command> [options]

    Commands:
      apply-symlinks      Apply symlinks for configs and scripts.
      install-dwm         Install dwm.
      rebuild-dwm         Reinstall dwm when config is updated.
      install-st          Install st.
      rebuild-st          Reinstall st when config is updated.
      install-dmenu       Install dmenu.
      rebuild-dmenu       Reinstall dmenu when config is updated.
      install-slock       Install slock.
      rebuild-slock       Reinstall slock when config is updated.
      install-dwmblocks   Install dwmblocks.
      rebuild-dwmblocks   Reinstall dwmblocks when config is updated.
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
    install-st)
        install_st
        ;;
    rebuild-st)
        rebuild_st
        ;;
    install-dmenu)
        install_dmenu
        ;;
    rebuild-dmenu)
        rebuild_dmenu
        ;;
    install-slock)
        install_slock
        ;;
    rebuild-slock)
        rebuild_slock
        ;;
    install-dwmblocks)
        install_dwmblocks
        ;;
    rebuild-dwmblocks)
        rebuild_dwmblocks
        ;;
    help | *)
        show_help
        ;;
esac
