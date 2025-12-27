#!/usr/bin/env fish
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+
set volume (pactl list sinks | grep Volume | head -n1 | awk '{print $5}' | sed 's/[%|,]//g') 
notify-send -i ~/.local/share/icons/RedCowboy/256x256/status/audio-volume-high.png " ++《✧╞══ Volume Up ══╡✧》++ " -h int:value:$volume "✧ ▬▭▬ ▬▭▬ ✦✧✦ ▬▭▬ ▬▭▬ ✧"