#!/usr/bin/env bash

FALLBACK="⭒✮⭒ Derek's Desktop ⭒✮⭒"
BASE_TARGET_LEN=35
PAD_CHAR="═"
ICON_COST=0

TRAY_COUNT=$(niri msg windows | grep -c Title)

TARGET_LEN=$(( BASE_TARGET_LEN - (TRAY_COUNT * ICON_COST) ))

niri msg windows | awk \
    -v fallback="$FALLBACK" \
    -v target="$TARGET_LEN" \
    -v pad="$PAD_CHAR" '
/^Window ID/ {
    active = ($0 ~ /\(focused\)/)
}

/^[[:space:]]+Title:/ && active {
    sub(/^[[:space:]]+Title: "/, "")
    sub(/"$/, "")
    text = $0
    found = 1
}

END {
    if (!found) {
        text = fallback
    }

    text_len = length(text)

    if (text_len >= target) {
        max_text_len = target - 3
        text = substr(text, 1, max_text_len) "..."
    }

    pad_total = target - text_len
    left_pad  = int(pad_total / 2)
    right_pad = pad_total - left_pad

    left  = ""
    right = ""

    for (i = 0; i < left_pad; i++)  left  = left  pad
    for (i = 0; i < right_pad; i++) right = right pad

    print left " " text " " right
}
'