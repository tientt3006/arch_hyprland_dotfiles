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

return M
