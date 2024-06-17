#!/bin/sh

handler() {
    local full_cmd="$@"
    local trimmed_cmd=${full_cmd:2}     # strip icons and space 
    case "$trimmed_cmd" in
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
        "QjackCtl")
            nohup qjackctl > /tmp/nohup.qjackctl.out 2>&1 & disown;exit
            ;;
        *)
            :
            ;;
    esac
}


# --- add commands here ---
handler $(cat <<-EOF | sort | dmenu -i
󰿅  Logout
󰑓  Reboot
󰤆  Shutdown
󰈹  Firefox
󱡫  QjackCtl
EOF
)

