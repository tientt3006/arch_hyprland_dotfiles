-- modules/workspace_scripts.lua
local M = {}

function M.move_all_to_ws(target)
    return function()
        local wins = hl.get_workspace_windows(hl.get_active_workspace())
        for _, w in ipairs(wins) do
            hl.dispatch(hl.dsp.window.move({ workspace = target, window = w }))
        end
        hl.dispatch(hl.dsp.focus({ workspace = target }))
    end
end

function M.swap_ws(target)
    return function()
        local cur_ws = hl.get_active_workspace()
        local cur_wins = hl.get_workspace_windows(cur_ws)
        local tgt_wins = hl.get_workspace_windows(target)
        local cur_id = cur_ws.id
        for _, w in ipairs(tgt_wins) do
            hl.dispatch(hl.dsp.window.move({ workspace = cur_id, window = w }))
        end
        for _, w in ipairs(cur_wins) do
            hl.dispatch(hl.dsp.window.move({ workspace = target, window = w }))
        end
        hl.dispatch(hl.dsp.focus({ workspace = target }))
    end
end

function M.setup_zoom(mainMod)
    local function handle_zoom(direction)
        local current = hl.get_config("cursor:zoom_factor") or 1.0
        if type(current) ~= "number" then current = 1.0 end
        
        if direction == "in" then
            current = current + 0.25
        else
            current = current - 0.25
            if current < 1.0 then current = 1.0 end
        end
        
        hl.config({
            cursor = {
                zoom_factor = current
            }
        })
    end

    hl.bind(mainMod .. " + SHIFT + mouse_up",   function() handle_zoom("in") end)
    hl.bind(mainMod .. " + SHIFT + mouse_down", function() handle_zoom("out") end)
end

function M.setup_alttab()
    local cycling = false
    local reset_timer = nil

    local function reset_state()
        cycling = false
    end

    local function focus_last()
        local last = hl.get_last_window()
        if last then
            hl.dispatch(hl.dsp.focus({ window = last }))
            hl.dispatch(hl.dsp.window.bring_to_top())
        end
    end

    local function on_alttab()
        if reset_timer then
            reset_timer:set_enabled(false)
        end

        if not cycling then
            -- Lần đầu: nhảy về window gần nhất
            focus_last()
            cycling = true
        else
            -- Giữ Alt, Tab tiếp: cycle qua tất cả window
            hl.dispatch(hl.dsp.window.cycle_next())
            hl.dispatch(hl.dsp.window.bring_to_top())
        end

        -- Nếu không nhấn gì trong 400ms, coi như nhả Alt -> reset
        reset_timer = hl.timer(reset_state, { timeout = 400, type = "oneshot" })
    end

    local function on_alttab_prev()
        if reset_timer then
            reset_timer:set_enabled(false)
        end

        if not cycling then
            focus_last()
            cycling = true
        else
            hl.dispatch(hl.dsp.window.cycle_next({ prev = true }))
            hl.dispatch(hl.dsp.window.bring_to_top())
        end

        reset_timer = hl.timer(reset_state, { timeout = 400, type = "oneshot" })
    end

    hl.bind("ALT + Tab",         on_alttab)
    hl.bind("ALT + SHIFT + Tab", on_alttab_prev)
end

return M
