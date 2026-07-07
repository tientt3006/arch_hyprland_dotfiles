-- ~/.config/hypr/hyprland.lua
-- Cấu hình Hyprland Lua mode - Đã được module hóa
-- Tất cả thiết lập chi tiết nằm trong thư mục: ~/.config/hypr/modules/

-- Xóa cache của các module để đảm bảo `hyprctl reload` nhận code mới
for k in pairs(package.loaded) do
    if k:match("^modules%.") then
        package.loaded[k] = nil
    end
end

require("modules.monitors")
require("modules.autostart")
require("modules.look_and_feel")
require("modules.input")
require("modules.rules")

-- Nạp keybinds (module này tự động nạp float_cascade và workspace_scripts)
require("modules.keybinds")
