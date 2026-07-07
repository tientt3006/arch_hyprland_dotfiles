#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu"
theme='config'

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`cat /etc/hostname`

# Options
shutdown='󰐥  [Alt+s] Shutdown'
reboot='󰜉  [Alt+r] Reboot'
lock='󰌾  [Alt+l] Lock'
suspend='󰤄  [Alt+u] Suspend'
logout='󰍃  [Alt+e] Logout'
yes='󰄬  [Alt+y] Yes'
no='󰅖  [Alt+n] No'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi \
		-kb-screenshot "" \
		-kb-select-1 "Alt+l" \
		-kb-select-2 "Alt+u" \
		-kb-select-3 "Alt+e" \
		-kb-select-4 "Alt+r" \
		-kb-select-5 "Alt+s"
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 1; lines: 2;}' \
		-theme-str 'element-text {horizontal-align: 0.5; font: "JetBrainsMono Nerd Font 13";}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ${dir}/${theme}.rasi \
		-kb-select-1 "Alt+y" \
		-kb-select-2 "Alt+n"
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
			mpc -q pause 2>/dev/null
			amixer set Master mute 2>/dev/null
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			uwsm stop
			# ~/.config/hypr/scripts/sys_logout.sh
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
