#!/bin/bash
# local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd

kitty -t ya_tui_win fish -c  yazi ; exit

# IFS= read -r -d '' cwd < "$tmp"
# [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
# rm -f -- "$tmp"


