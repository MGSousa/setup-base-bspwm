#!/bin/sh

ip_target=$(awk '{print $1}' ~/.config/polybar/shapes/scripts/target)
name_target=$(awk '{print $2}' ~/.config/polybar/shapes/scripts/target)

if [ $ip_target ] && [ $name_target ]; then
  echo "%{F#ffffff}什%{F#ffffff} $ip_target - $name_target "
elif [ $(<~/.config/polybar/shapes/scripts/target wc -w) -eq 1 ]; then
  echo "%{F#ffffff}什%{F#ffffff} $ip_target "
else
  echo "%{F#ffffff}什%{u-}%{F#ffffff} No target "
fi
