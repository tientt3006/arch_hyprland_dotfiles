-- modules/keybinds.lua
local float_cascade = require("modules.float_cascade")
local ws_scripts = require("modules.workspace_scripts")

local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("uwsm app -- kitty --single-instance"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("uwsm app -- thunar"))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd("pkill rofi || uwsm app -- rofi -show drun -theme $HOME/.config/rofi/config.rasi"))
hl.bind(mainMod .. " + Tab",    hl.dsp.exec_cmd("pkill rofi || uwsm app -- rofi -show window -theme $HOME/.config/rofi/config.rasi"))
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("pkill rofi || uwsm app -- $HOME/.config/rofi/clipboard.sh"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("uwsm app -- kitty --name floating_fzf --class floating_fzf -e $HOME/.config/hypr/scripts/fzf-finder.sh"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("uwsm app -- kitty --name floating_fzf --class floating_fzf -e $HOME/.config/hypr/scripts/live-grep.sh"))

-- Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("uwsm app -- kitty --name floating_fzf --class floating_fzf -e $HOME/.config/hypr/scripts/fzf_wallpaper.sh"))
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/random_wallpaper.sh"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/apply_static_theme.sh"))

-- Notifications / waybar
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))

-- Window management
hl.bind(mainMod .. " + CTRL + W", hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + O",         hl.dsp.layout("togglesplit"))

-- System
hl.bind("ALT + F4",                    hl.dsp.exec_cmd("pkill rofi || $HOME/.config/rofi/powermenu/powermenu.sh"))
hl.bind(mainMod .. " + CTRL + SHIFT + L",      hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + CTRL + ALT + L",  hl.dsp.exec_cmd("uwsm stop"))
hl.bind(mainMod .. " + CTRL + SHIFT + U", hl.dsp.exec_cmd("loginctl lock-session && sleep 1 && systemctl suspend"))
hl.bind(mainMod .. " + CTRL + ALT + U",   hl.dsp.exec_cmd("systemctl poweroff"))
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("systemctl reboot"))

-- Custom floating logic
hl.bind(mainMod .. " + S", float_cascade.toggle_all_float)

-- Screenshots
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grim - | tee \"$HOME/OneDrive/Pictures/Screenshots/$(date +'%s_grim.png')\" | wl-copy && notify-send \"Screenshot\" \"Fullscreen captured\""))
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | tee \"$HOME/OneDrive/Pictures/Screenshots/$(date +'%s_grim.png')\" | wl-copy && notify-send \"Screenshot\" \"Region captured\""))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h",     hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j",     hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k",     hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l",     hl.dsp.focus({ direction = "right" }))

-- Move window
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

-- Window switching (Windows-like Alt-Tab via submap)
local alttab = ws_scripts.setup_alttab()
hl.bind("ALT + Tab",         alttab.next)
hl.bind("ALT + SHIFT + Tab", alttab.prev)

-- Workspaces
for i = 1, 9 do
    local key = tostring(i)
    hl.bind(mainMod .. " + " .. key,               hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,       hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + ALT + " .. key,         ws_scripts.move_all_to_ws(i))
    hl.bind(mainMod .. " + SHIFT + ALT + " .. key, ws_scripts.swap_ws(i))
end

-- Workspace 10 (key 0)
hl.bind(mainMod .. " + 0",                 hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0",         hl.dsp.window.move({ workspace = 10 }))
hl.bind(mainMod .. " + ALT + 0",           ws_scripts.move_all_to_ws(10))
hl.bind(mainMod .. " + SHIFT + ALT + 0",   ws_scripts.swap_ws(10))

-- Mouse: scroll workspace
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + ALT + l", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + ALT + h",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse: move / resize window
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Zoom
hl.bind(mainMod .. " + ALT + mouse_up",   function() ws_scripts.zoom("in") end)
hl.bind(mainMod .. " + ALT + mouse_down", function() ws_scripts.zoom("out") end)
hl.bind(mainMod .. " + ALT + equal",      function() ws_scripts.zoom("in") end)
hl.bind(mainMod .. " + ALT + minus",      function() ws_scripts.zoom("out") end)


-- Brightness
hl.bind("XF86MonBrightnessUp",          hl.dsp.exec_cmd("brightnessctl set +5%"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",        hl.dsp.exec_cmd("brightnessctl set 5%-"),  { locked = true, repeating = true })
hl.bind(mainMod .. " + CTRL + equal",      hl.dsp.exec_cmd("brightnessctl set +5%"),  { locked = true, repeating = true })
hl.bind(mainMod .. " + CTRL + minus",    hl.dsp.exec_cmd("brightnessctl set 5%-"),  { locked = true, repeating = true })
hl.bind(mainMod .. " + CTRL + plus",       hl.dsp.exec_cmd("brightnessctl set +5%"),  { locked = true, repeating = true })
hl.bind(mainMod .. " + CTRL + underscore", hl.dsp.exec_cmd("brightnessctl set 5%-"),  { locked = true, repeating = true })

-- Volume
hl.bind("XF86AudioRaiseVolume",     hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",     hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),             { locked = true, repeating = true })
hl.bind("XF86AudioMute",            hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),            { locked = true })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.5"), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),           { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + plus",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.5"), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + underscore", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind(mainMod .. " + M",  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

-- Lid switch
hl.bind("switch:on:Lid Switch", function()
    os.execute("loginctl lock-session &")
    hl.dsp.dpms('off')
end, { locked = true })
hl.bind("switch:off:Lid Switch", function() hl.dsp.dpms('on') end, { locked = true })
