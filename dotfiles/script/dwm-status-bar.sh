#!/bin/sh
# REQUIRES FONT-AWESOME PACKAGE TO WORK PROPERLY


cpu() {
  cpu="$(ps -eo %cpu | awk '{sum +=$1} END {print sum}')"
  echo "  $cpu% "
}

hdd(){
  hdd="$(df -h ${HOME} | grep dev | awk '{printf $3 "/"  $2}')"
  echo "  $hdd"
}

mem(){
  mem="$(free -h | awk '/Mem:/ {printf $3 "/" $2}')"
  echo "  $mem"
}

upgrades(){
#   upgrades="$(paru -Qu | wc -l)"
#   echo "  $upgrades"
  echo "  0"
}

pkgs(){
  pkgs="$(paru -Qqe | wc -l)"
  echo "  $pkgs"
}

vol(){
  vol="$(amixer get Master | grep -oE '[0-9]+%')"
  echo "  $vol"
}

dte(){
  dte="$(date +"%a, %b %d %R")"
  echo "$dte"
}

status(){
  echo "$(cpu) | $(mem) | $(hdd) | $(upgrades)  | $(pkgs)  | $(vol) | $(dte)"
}


while true; do
  xsetroot -name "$(status)"
  sleep 10s 
done
