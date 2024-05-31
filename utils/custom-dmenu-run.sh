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
        "Firefox")
            nohup firefox > /tmp/nohup.firefox.out 2>&1 & disown;exit
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
Firefox
EOF
)

