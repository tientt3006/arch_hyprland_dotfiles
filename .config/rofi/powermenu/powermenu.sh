#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu"
theme='config'

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`cat /etc/hostname`

# Options
shutdown='󰐥  [s] Shutdown'
reboot='󰜉  [r] Reboot'
lock='󰌾  [l] Lock'
suspend='󰤄  [u] Suspend'
logout='󰍃  [e] Logout'
yes='󰄬  [y] Yes'
no='󰅖  [n] No'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi \
		-kb-custom-1 "s,S" \
		-kb-custom-2 "r,R" \
		-kb-custom-3 "l,L" \
		-kb-custom-4 "u,U" \
		-kb-custom-5 "e,E"
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5; font: "JetBrainsMono Nerd Font 13";}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ${dir}/${theme}.rasi \
		-kb-custom-1 "y,Y" \
		-kb-custom-2 "n,N"
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	exit_code=$?
	if [[ $exit_code -eq 10 || "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			mpc -q pause
			amixer set Master mute
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			hyprctl dispatch exit
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
exit_code=$?

if [[ $exit_code -eq 10 || "$chosen" == "$shutdown" ]]; then
	run_cmd --shutdown
elif [[ $exit_code -eq 11 || "$chosen" == "$reboot" ]]; then
	run_cmd --reboot
elif [[ $exit_code -eq 12 || "$chosen" == "$lock" ]]; then
	if [[ -x '/usr/bin/hyprlock' ]]; then
		hyprlock
	fi
elif [[ $exit_code -eq 13 || "$chosen" == "$suspend" ]]; then
	run_cmd --suspend
elif [[ $exit_code -eq 14 || "$chosen" == "$logout" ]]; then
	run_cmd --logout
fi
