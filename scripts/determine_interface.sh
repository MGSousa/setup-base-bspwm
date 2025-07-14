#!/bin/sh

INTERFACE=$(ifconfig | head -1 | awk -F: '{print $1}')

for file in $(grep -rsl 'eth0' ./config/ | xargs); do
  sed -i -e "s/eth0/$INTERFACE/" $file
done
