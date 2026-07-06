#!/bin/bash
# Trở về giao diện tĩnh (Catppuccin Mocha)
wallust theme Catppuccin-Mocha
hyprctl reload
killall -SIGUSR2 waybar
swaync-client -rs
# killall -SIGUSR1 kitty
