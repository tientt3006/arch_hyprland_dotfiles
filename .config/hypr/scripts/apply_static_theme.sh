#!/bin/bash
# Trở về giao diện tĩnh (Catppuccin Mocha)
wallust theme Catppuccin-Mocha
killall -SIGUSR2 waybar
swaync-client -rs
killall -SIGUSR1 kitty
