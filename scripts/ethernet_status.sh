#!/bin/sh

echo "%{F#ffffff}  %{F#ffffff}$(/usr/sbin/ifconfig $(ifconfig | head -1 | awk -F: '{print $1}') | grep "inet " | awk '{print $2}')%{u-}"
