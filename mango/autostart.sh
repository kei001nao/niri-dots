#! /bin/bash
set +e

/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
/usr/bin/awww-daemon &
/usr/bin/waybar &
/usr/bin/vicinae server &
$HOME/.config/scripts/start-sunsetr.sh start
