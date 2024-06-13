#!/bin/sh
# REQUIRES FONT-AWESOME PACKAGE TO WORK PROPERLY

SCRIPT_NAME=$(basename "$0")
REFRESH_RATE=10s

print_help(){
    cat<<-EOF
Usage:
    $SCRIPT_NAME <command> [options]
Commands:
    status
        Print to stdout current state of dwm status bar
    start
        Continuously update the dwm status bar (every $REFRESH_RATE)
    refresh
        Immediately update the dwm status bar
EOF
}

cpu() {
    cpu="$(ps -eo %cpu | awk '{sum +=$1} END {print sum}')"
    echo " $cpu%"
}

mem(){
    mem="$(free -h | awk '/Mem:/ {printf $3 "/" $2}')"
    echo " $mem"
}

hdd(){
    hdd="$(df -h ${HOME} | grep dev | awk '{printf $3 "/"  $2}')"
    echo "󰋊 $hdd"
}

upgrades(){
    # this constantly sends request to remote repos
    # which is not efficient and may lead to barring
    upgrades="$(paru -Qu | wc -l)"
    echo "󰚰 $upgrades"
}

net(){
    # may be useful if using wifi
    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
        net=on
    else
        net=off
    fi
    echo "󱘖 $net"
}

pkgs(){
  pkgs="$(paru -Qqe | wc -l)"
  echo " $pkgs"
}

vol(){
    vol="$(amixer get Master | grep -oE '[0-9]+%')"
    echo " $vol"
}

dte(){
    dte="$(date +"%a, %b %d %R")"
    echo "$dte"
}

status(){
    echo " $(cpu) | $(mem) | $(hdd) | $(pkgs) | $(vol) | $(dte)"
}

start(){
    while true; do
        xsetroot -name "$(status)"
        sleep $REFRESH_RATE
    done
}

refresh(){
    local this_pid=$$
    local pids=$(pgrep -f "$SCRIPT_NAME")
    local target_pid=$(echo $pids | sed "s/$this_pid//g" | tr -s ' ')
    pkill -P $target_pid sleep
}


parse_options(){
    if [ "$#" -gt 0 ]; then
        CMD="$1"
        shift
    else
        print_help && exit 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            *)
                printf "Error: Unknown option $1\n"
                print_help && exit 1
            ;;
        esac
    done
}

parse_command(){
	case "$CMD" in
		"status")
			status
			;;
		"start")
			start
			;;
		"refresh")
			refresh
			;;
		*)
			printf "Error: Unknown command $CMD\n"
			print_help && exit 1
			;;
	esac
}

parse_options "$@"
parse_command

