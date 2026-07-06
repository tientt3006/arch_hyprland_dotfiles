-- modules/look_and_feel.lua
local colors = require("wallust-colors")

hl.config({
    misc = {
        focus_on_activate = true
    },
    
    cursor = {
        no_hardware_cursors = true,
    },

    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 0,
        
        col = {
            active_border = { colors = { colors.color1, colors.color2 }, angle = 45 },
            inactive_border = colors.background,
        },

        layout = "dwindle",
        allow_tearing = true,
    },

    decoration = {
        rounding = 10,
        active_opacity = 0.97,
        inactive_opacity = 0.93,

        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            ignore_opacity = true,
        },

        shadow = {
            enabled = false,
            range = 25,
            render_power = 3,
            color = "rgba(11111be6)",
        },
    },

    animations = {
        enabled = true,
    },
    
    dwindle = {
        preserve_split = true,
        force_split = 2,
        smart_split = false,
    },
    
    master = {
        new_status = "master",
    }
})

-- Animations Curves setup
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default" })
