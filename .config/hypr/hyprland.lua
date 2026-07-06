-- ~/.config/hypr/hyprland.lua
-- Cấu hình Hyprland Lua mode - Đã được module hóa
-- Tất cả thiết lập chi tiết nằm trong thư mục: ~/.config/hypr/modules/

-- Cần nạp file màu trước nếu các module khác cần sử dụng
-- Nhưng trong trường hợp này các module đã tự require màu nếu cần.

require("modules.monitors")
require("modules.autostart")
require("modules.look_and_feel")
require("modules.input")
require("modules.rules")

-- Nạp keybinds (module này tự động nạp float_cascade và workspace_scripts)
require("modules.keybinds")
