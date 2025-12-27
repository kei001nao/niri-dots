#!/usr/bin/env fish
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-
set volume (pactl list sinks | grep Volume | head -n1 | awk '{print $5}' | sed 's/[%|,]//g') 
notify-send -i ~/.local/share/icons/RedCowboy/256x256/status/audio-volume-low.png " --《✧╞══ Volume Down ══╡✧》-- " -h int:value:$volume "✧ ▬▭▬ ▬▭▬ ✦✧✦ ▬▭▬ ▬▭▬ ✧"