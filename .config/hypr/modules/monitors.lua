-- modules/monitors.lua
local colors = require("wallust-colors")

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

require("monitors")

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60.0",
    position = "0x0",
    scale = 1.0,
    -- CssGap format: {top=, bottom=, left=, right=}
    reserved_area = { top = 50, bottom = 30, left = 0, right = 0 },
})
