#!/bin/sh

OUT=$(ps aux --no-headers | sort -nk 3 | awk '{print $3 "% / MEM:"$4" :: "$11}' | tail -1)
printf "%s" "$OUT"
