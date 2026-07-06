-- modules/autostart.lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("uwsm app -- awww-daemon --quiet")
    hl.exec_cmd("uwsm app -- awww img \"$HOME/GDrive_bisync/picture/Saved pics/arch_wallpapers/d_void.png\"")
    hl.exec_cmd("uwsm app -- easyeffects --gapplication-service")
    hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
    hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
end)
