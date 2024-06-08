#!/bin/sh

SCRIPT_NAME=$(basename "$0")
BODHI_ROOT=$(dirname "$(realpath "$0")")

# TODO:
# - command to list utils
# - add auto complete

save_pkglist() {
    paru -Qqe > ${BODHI_ROOT}/dotfiles/package/pkglist.txt
    paru -Qqen > ${BODHI_ROOT}/dotfiles/package/pkglist.official.txt
    paru -Qqem > ${BODHI_ROOT}/dotfiles/package/pkglist.foreign.txt
}

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
    ln -sfv ${BODHI_ROOT}/dotfiles/config/init.lua ~/.config/nvim/init.lua
    ln -sfv ${BODHI_ROOT}/dotfiles/config/dunstrc ~/.config/dunst/dunstrc


    sudo ln -sfv ${BODHI_ROOT}/dotfiles/config/custom-gruvbox.omp.json ~/.cache/oh-my-posh/themes/custom-gruvbox.omp.json
    sudo ln -sfv ${BODHI_ROOT}/dotfiles/script/on-login-script.sh /etc/profile.d/on-login-script.sh
}

install_dwm() {
    cd ${BODHI_ROOT}/dwm || exit
    sudo make clean install
}


install_st() {
    cd ${BODHI_ROOT}/st || exit
    sudo make clean install
}


install_dmenu() {
    cd ${BODHI_ROOT}/dmenu || exit
    sudo make clean install
}


install_slock() {
    cd ${BODHI_ROOT}/slock || exit
    sudo make clean install
}


install_dwmblocks() {
    cd ${BODHI_ROOT}/dwmblocks || exit
    sudo make clean install
}


install_bluez_alsa() {
    cd bluez-alsa
        autoreconf --install --force
        mkdir -p build
        cd build
            ../configure --enable-aac --enable-systemd
            make
            sudo make install
    cd ${BODHI_ROOT}
    sudo systemctl enable bluealsa.service
    sudo systemctl enable bluealsa-aplay.service
    # use sudo make uninstall to remove
}


show_help() {
    cat <<-EOF
    Usage: $SCRIPT_NAME <command> [options]

    Commands:
      save-pkglist        Save currently installed packages to txt file.
      apply-symlinks      Apply symlinks for configs and scripts.
      install-dwm         Install/rebuild dwm.
      install-st          Install/rebuild st.
      install-dmenu       Install/rebuild dmenu.
      install-slock       Install/rebuild slock.
      install-dwmblocks   Install/rebuild dwmblocks.
      install-bleuz-alsa  Install bluez-alsa daemon and utils.
      help                Show this help message.
EOF
}

case "$1" in
    save-pkglist)
        save_pkglist
        ;;
    apply-symlinks)
        apply_symlinks
        ;;
    install-dwm)
        install_dwm
        ;;
    install-st)
        install_st
        ;;
    install-dmenu)
        install_dmenu
        ;;
    install-slock)
        install_slock
        ;;
    install-dwmblocks)
        install_dwmblocks
        ;;
    install-bluez-alsa)
        install_bluez_alsa
        ;;
    help | *)
        show_help
        ;;
esac
