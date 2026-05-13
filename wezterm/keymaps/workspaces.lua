local M = {}

-- Workspace-related leader bindings.
function M.append(keys, wezterm, workspaces)
	table.insert(keys, { key = "s", mods = "LEADER", action = wezterm.action_callback(workspaces.workspace_menu) })
	table.insert(keys, { key = "R", mods = "LEADER|SHIFT", action = workspaces.rename_workspace() })
end

return M
