#!/bin/sh

handler() {
    case "$1" in
        "Logout")
            slock
            ;;
        "Reboot")
            sudo systemctl reboot
            ;;
        "Shutdown")
            sudo systemctl poweroff
            ;;
        *)
            :
            ;;
    esac
}


# --- add commands here ---
handler $(cat <<-EOF | sort | dmenu -i
Logout
Reboot
Shutdown
EOF
)

