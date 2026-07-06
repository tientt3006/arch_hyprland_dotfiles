-- modules/rules.lua
hl.layer_rule({ name = "rofi-blur", match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "swaync-cc-blur", match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "swaync-noti-blur", match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.5 })

hl.window_rule({ name = "fzf-rules", match = { class = "^(floating_fzf)$" }, float = true, center = true, size = "1400 800", animation = "popin" })
