local M = {}

-- Project launcher: switch to a named workspace and start in its root.
function M.append(keys, wezterm, workspaces, constants)
	local act = wezterm.action
	local projects = {
		{ id = "wezterm", label = "WezTerm config", workspace = "wezterm", path = constants.CONFIG_DIR },
		{ id = "config", label = "Dot config", workspace = "config", path = constants.HOME .. "/.config" },
		{ id = "nvim", label = "Neovim config", workspace = "nvim", path = constants.HOME .. "/AppData/Local/nvim" },
		{ id = "uni", label = "UNI", workspace = "uni", path = constants.HOME .. "/UNI" },
		{ id = "dev", label = "Downloads Development", workspace = "dev", path = constants.HOME .. "/Downloads/Development" },
		{ id = "g", label = "G drive", workspace = "g-drive", path = "G:/" },
	}

	local by_id = {}
	local choices = {}
	for _, project in ipairs(projects) do
		by_id[project.id] = project
		table.insert(choices, {
			id = project.id,
			label = project.label .. "  ->  " .. project.workspace,
		})
	end

	table.insert(keys, {
		key = "P",
		mods = "LEADER|SHIFT",
		action = act.InputSelector({
			title = "Project workspace",
			description = "Switch to a project workspace",
			fuzzy_description = "Project: ",
			fuzzy = true,
			choices = choices,
			action = wezterm.action_callback(function(window, pane, id)
				local project = id and by_id[id]
				if not project then
					return
				end

				local current_workspace = window:active_workspace()
				if current_workspace ~= project.workspace and current_workspace ~= constants.DEFAULT_WORKSPACE then
					workspaces.save_workspace_by_name(current_workspace)
				end

				for _, name in ipairs(workspaces.get_mux_workspace_names()) do
					if name == project.workspace then
						window:perform_action(act.SwitchToWorkspace({ name = project.workspace }), pane)
						workspaces.touch_workspace_order(project.workspace)
						return
					end
				end

				if workspaces.restore_workspace_by_name(project.workspace) then
					workspaces.touch_workspace_order(project.workspace)
					window:perform_action(act.SwitchToWorkspace({ name = project.workspace }), pane)
					return
				end

				window:perform_action(
					act.SwitchToWorkspace({
						name = project.workspace,
						spawn = { cwd = project.path },
					}),
					pane
				)
				workspaces.touch_workspace_order(project.workspace)
			end),
		}),
	})
end

return M
