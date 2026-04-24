local act = require("wezterm").action

local M = {}

-- Pane movement and resizing bindings.
function M.append(keys)
	table.insert(keys, { key = "]", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) })
	table.insert(keys, { key = "[", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) })
	table.insert(keys, { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") })
	table.insert(keys, { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") })
	table.insert(keys, { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") })
	table.insert(keys, { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") })
	table.insert(keys, { key = "phys:Space", mods = "LEADER", action = act.RotatePanes("Clockwise") })
	table.insert(keys, { key = "z", mods = "LEADER", action = act.TogglePaneZoomState })
	table.insert(keys, { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) })
	table.insert(keys, { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) })
end

return M
