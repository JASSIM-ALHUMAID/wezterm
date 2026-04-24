local act = require("wezterm").action

local M = {}

-- Tab management bindings.
function M.append(keys, _, workspaces)
	table.insert(keys, { key = "w", mods = "LEADER", action = act.ShowTabNavigator })
	table.insert(keys, { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") })
	table.insert(keys, { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) })
	table.insert(keys, { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) })
	table.insert(keys, { key = ",", mods = "LEADER", action = workspaces.rename_tab_title() })
	table.insert(keys, { key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) })
end

return M
