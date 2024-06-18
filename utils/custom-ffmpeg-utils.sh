#!/bin/bash

screen_audio_capture()
{
    local dest=${HOME}/Documents/videos/$(date +"%Y-%m-%d-%H-%M-%S-%N").mkv
    local slop=$(slop \
        --noopengl \
        --highlight \
        --tolerance=0 \
        --color=0.27,0.52,0.53,0.5 \
        --format="%x %y %w %h %g %i" \
    ) || exit 1
    read -r X Y W H G ID <<< $slop
    ffmpeg -f x11grab -s "$W"x"$H" -i :0.0+$X,$Y -f alsa -ac 2 -i hw:0 ${dest}
    notify-send --urgency low "Screen Audio Capture" "$dest"
}

