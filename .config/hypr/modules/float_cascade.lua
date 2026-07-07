-- modules/float_cascade.lua
local M = {}

-- Float-daemon thay thế: tự động float cửa sổ mới nếu workspace đang ở float mode
hl.on("window.open", function(win)
    if not win then return end
    local ws = win.workspace
    if not ws then return end
    local ws_name = ws.name or tostring(ws.id)
    local state_file = "/tmp/hypr_float_mode_" .. ws_name
    -- Kiểm tra trạng thái float mode cho workspace này
    local f = io.open(state_file, "r")
    if f then
        f:close()
        -- Cấu hình cascade
        local SAFE_MARGIN_TOP  = 110
        local SAFE_MARGIN_LEFT = 10
        local CASCADE_STEP     = 30

        -- Lấy thông vị trí monitor (có offset đa màn hình)
        local mon = hl.get_active_monitor()
        local scale  = mon and mon.scale  or 1
        local mw     = mon and mon.width  or 1920
        local mh     = mon and mon.height or 1080
        local rw = math.floor(mw / scale * 0.8)
        local rh = math.floor(mh / scale * 0.8)

        -- Đếm số cửa sổ đang có trong workspace (trừ cửa sổ vừa mở)
        local wins = hl.get_workspace_windows(ws)
        local count = 0
        for _, w in ipairs(wins) do
            if w.address ~= win.address then
                count = count + 1
            end
        end

        -- Tính vị trí cascade (tọa độ tuyệt đối đa màn hình)
        local mon_x  = mon and mon.x or 0
        local mon_y  = mon and mon.y or 0
        local pos_x  = mon_x + SAFE_MARGIN_LEFT + (count * CASCADE_STEP)
        local pos_y  = mon_y + SAFE_MARGIN_TOP  + (count * CASCADE_STEP)

        -- Float, resize, rồi đặt vào vị trí cascade
        hl.dispatch(hl.dsp.window.float({ action = "set",  window = win }))
        hl.dispatch(hl.dsp.window.resize({ x = rw, y = rh, window = win }))
        hl.dispatch(hl.dsp.window.move({ x = pos_x, y = pos_y, window = win }))
    end
end)

function M.toggle_all_float()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local ws_id   = ws.id
    local ws_name = ws.name or tostring(ws_id)

    -- Cấu hình vùng an toàn (giống script cũ)
    local SAFE_MARGIN_TOP    = 110
    local SAFE_MARGIN_BOTTOM = 60
    local SAFE_MARGIN_LEFT   = 10
    local SAFE_MARGIN_RIGHT  = 10
    local CASCADE_STEP       = 30

    -- Lấy thông tin monitor (có offset đa màn hình)
    local mon = hl.get_active_monitor()
    if not mon then return end
    local l_w = math.floor(mon.width  / mon.scale)
    local l_h = math.floor(mon.height / mon.scale)
    local safe_w   = l_w - SAFE_MARGIN_LEFT - SAFE_MARGIN_RIGHT
    local safe_h   = l_h - SAFE_MARGIN_TOP  - SAFE_MARGIN_BOTTOM
    local target_w = math.floor(safe_w * 0.8)
    local target_h = math.floor(safe_h * 0.8)

    -- Tọa độ tuyệt đối (absolute global coordinates, giống script gốc)
    local abs_start_x = mon.x + SAFE_MARGIN_LEFT
    local abs_start_y = mon.y + SAFE_MARGIN_TOP

    local state_file = "/tmp/hypr_float_mode_" .. ws_name
    local wins = hl.get_workspace_windows(ws)

    -- Kiểm tra trạng thái qua file (đồng bộ với float-daemon.sh)
    local in_float_mode = (io.open(state_file, "r") ~= nil)

    if in_float_mode then
        -- ---- TILING MODE ----
        os.remove(state_file)
        hl.notification.create({ text = "Workspace " .. ws_name .. ": Tiling Mode", timeout = 2000 })
        for _, w in ipairs(wins) do
            hl.dispatch(hl.dsp.window.float({ action = "toggle", window = w }))
        end
    else
        -- ---- FLOAT MODE ----
        -- Tạo file state để float-daemon.sh nhận biết
        local f = io.open(state_file, "w")
        if f then f:close() end
        hl.notification.create({ text = "Workspace " .. ws_name .. ": Float Mode", timeout = 2000 })

        -- Thu thập danh sách cửa sổ đang TILED (trước khi toggle)
        local tiled = {}
        for _, w in ipairs(wins) do
            if not w.floating then
                tiled[#tiled + 1] = w
            end
        end

        -- Toggle tất cả sang float
        for _, w in ipairs(wins) do
            hl.dispatch(hl.dsp.window.float({ action = "toggle", window = w }))
        end

        -- Resize + cascade positioning cho các cửa sổ vừa float (cũ là tiled)
        for idx, w in ipairs(tiled) do
            local i = idx - 1  -- 0-indexed cho cascade
            local pos_x = abs_start_x + (i * CASCADE_STEP)
            local pos_y = abs_start_y + (i * CASCADE_STEP)
            hl.dispatch(hl.dsp.window.resize({ x = target_w, y = target_h, window = w }))
            hl.dispatch(hl.dsp.window.move({ x = pos_x, y = pos_y, window = w }))
        end

        -- Đảm bảo cửa sổ đang focus được đẩy lên trên cùng
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
end

return M
