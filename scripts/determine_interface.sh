#!/bin/sh

INTERFACE=$(ip -br a | grep UP | awk '{print $1}')

for file in $(grep -rsl 'eth0' ./config/ | xargs); do
  sed -i -e "s/eth0/$INTERFACE/" "$file"
done
