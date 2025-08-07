#!/bin/sh

ifconfig "$(ip -br a | grep UP | awk '{print $1}')" | grep "inet " | awk '{print $2}'
