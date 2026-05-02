local M = {}

-- Project launcher: switch to a named workspace and start in its root.
function M.append(keys, wezterm, constants)
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

				window:perform_action(
					act.SwitchToWorkspace({
						name = project.workspace,
						spawn = { cwd = project.path },
					}),
					pane
				)
			end),
		}),
	})
end

return M
