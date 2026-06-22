#
#
if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

# if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
#  start-hyprland
# fi


