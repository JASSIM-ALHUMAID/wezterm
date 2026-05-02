local M = {}

-- Fuzzy launcher for common terminal workflows.
function M.append(keys, wezterm, workspaces, constants, helpers)
	local act = wezterm.action

	local commands = {
		{
			id = "workspace-menu",
			label = "Workspace menu",
			run = function(window, pane)
				workspaces.workspace_menu(window, pane)
			end,
		},
		{
			id = "edit-wezterm",
			label = "Edit WezTerm config",
			action = helpers.send_line('nvim "' .. constants.CONFIG_DIR .. '"'),
		},
		{
			id = "wezterm-config-dir",
			label = "cd WezTerm config",
			action = helpers.quick_cd(constants.CONFIG_DIR),
		},
		{
			id = "nvim-here",
			label = "Open nvim here",
			action = helpers.send_line("nvim ."),
		},
		{
			id = "yazi",
			label = "Open yazi",
			action = helpers.send_line("yazi"),
		},
		{
			id = "btop",
			label = "Open btop",
			action = helpers.send_line(constants.HOME .. "/Downloads/Development/btop4win/btop4win.exe"),
		},
		{
			id = "command-palette",
			label = "WezTerm command palette",
			action = act.ActivateCommandPalette,
		},
	}

	local by_id = {}
	local choices = {}
	for _, command in ipairs(commands) do
		by_id[command.id] = command
		table.insert(choices, { id = command.id, label = command.label })
	end

	table.insert(keys, {
		key = "m",
		mods = "LEADER",
		action = act.InputSelector({
			title = "Command launcher",
			description = "Run a common WezTerm workflow",
			fuzzy_description = "Command: ",
			fuzzy = true,
			choices = choices,
			action = wezterm.action_callback(function(window, pane, id)
				local command = id and by_id[id]
				if not command then
					return
				end

				if command.run then
					command.run(window, pane)
				else
					window:perform_action(command.action, pane)
				end
			end),
		}),
	})
end

return M
