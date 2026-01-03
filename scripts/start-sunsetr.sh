#!/bin/bash

PRESET_STR="$1"
BRIGHTNESS_DAY="70%"
BRIGHTNESS_NIGHT="60%"

  case "$PRESET_STR" in
  "status")
    output=$(sunsetr status)
    #brightnessctl set $brightstr
    notify-send -u normal "Sunsetr Status" "$output"  #\n   Brightness: $brightstr"
    exit 0
    ;;
  "day")
    prestr="day"
    #brightstr="$BRIGHTNESS_DAY"
    ;;
  "night")
    prestr="night"
    #brightstr="$BRIGHTNESS_NIGHT"
    ;;
  "gaming")
    prestr="gaming"
    #brightstr="100%"
    ;;
  "auto")
    prestr="autosunset"
    #brightstr="$BRIGHTNESS_DAY"
    ;;
  "start")
    # Start sunsetr. with preset based on day of week
    day=$(date +%u)  # 1=Monday, 7=Sunday

    if [ $day -ge 1 ] && [ $day -le 5 ]; then
       # Weekdays: work schedule with earlier transitions
       prestr="default"
    else
       # Weekends: relaxed schedule, sleep in
       prestr="weekend"
    fi
    #brightstr="$BRIGHTNESS_DAY"
    ;;

  esac

  sunsetr preset $prestr
  sleep 0.8

  output=$(sunsetr status)
  if echo "$output" | grep -q -i "night"; then
    brightstr="$BRIGHTNESS_NIGHT"
  else
    brightstr="$BRIGHTNESS_DAY"
  fi
  if echo "$output" | grep -q -i "gaming"; then
    brightstr="100%"
  fi

  brightnessctl set $brightstr
  notify-send -u normal "Setting Sunsetr" "$output\n   Brightness: $brightstr"

  exit 0
