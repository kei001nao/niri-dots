#!/bin/bash

# temaのウィンドウクラス名
TEMA_CLASS="li.oever.tema"

# hyprctlでtemaのウィンドウが存在するかどうかをjqで確認
if hyprctl clients -j | jq -e --arg CLASS "$TEMA_CLASS" '.[] | select(.class == $CLASS)' > /dev/null; then
    hyprctl dispatch focuswindow "^(li\.oever\.tema)$"
else
    # 存在しない場合、temaを起動する
    tema
fi
