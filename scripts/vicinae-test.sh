#!/bin/bash

/usr/bin/vicinae toggle
niri msg windows>niri-window.txt
niri msg layers>niri-layer.txt

/usr/bin/vicinae vicinae://extensions/sovereign/awww-switcher/wpgrid
niri msg windows>niri-window-awww.txt
niri msg layers>niri-layer-awww.txt
