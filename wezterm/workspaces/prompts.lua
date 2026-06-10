local Module = {}

-- User-facing workspace prompts and selectors.
function Module.attach(M, ctx)
	local wezterm = ctx.wezterm
	local act = ctx.act
	local constants = ctx.constants
	local helpers = ctx.helpers

	function M.switch_workspace(window, pane)
		local loaded_names = M.get_mux_workspace_names()
		local choices = {}

		for _, name in ipairs(loaded_names) do
			table.insert(choices, { id = name, label = name .. "  [loaded]" })
		end

		if #choices == 0 then
			window:toast_notification("WezTerm", "No workspaces found", nil, 3000)
			return
		end

		window:perform_action(
			act.InputSelector({
				title = "Switch workspace",
				description = "Switch to loaded workspace",
				fuzzy_description = "Search workspace: ",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end

					M.touch_workspace_order(id)
					inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
				end),
			}),
			pane
		)
	end

	function M.prompt_create_workspace(window, pane)
		window:perform_action(
			act.PromptInputLine({
				description = "Create workspace:",
				action = wezterm.action_callback(function(inner_window, inner_pane, line)
					if not line or line == "" then
						return
					end

					M.touch_workspace_order(line)
					inner_window:perform_action(act.SwitchToWorkspace({ name = line }), inner_pane)
				end),
			}),
			pane
		)
	end

	function M.workspace_menu(window, pane)
		local loaded_names = M.get_mux_workspace_names()
		local choices = {
			{ id = "__create__", label = "+ Create workspace" },
		}

		for _, name in ipairs(loaded_names) do
			table.insert(choices, { id = name, label = name .. "  [loaded]" })
		end

		window:perform_action(
			act.InputSelector({
				title = "Workspace",
				description = "Switch or create workspace",
				fuzzy_description = "Search workspace: ",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end

					if id == "__create__" then
						M.prompt_create_workspace(inner_window, inner_pane)
						return
					end

					M.touch_workspace_order(id)
					inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
				end),
			}),
			pane
		)
	end

	function M.rename_tab_title()
		return act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Renaming Tab Title...:" },
			}),
			action = wezterm.action_callback(function(window, _, line)
				if line and line ~= "" then
					window:active_tab():set_title(line)
				end
			end),
		})
	end

	function M.rename_workspace()
		return act.PromptInputLine({
			description = "Rename workspace:",
			action = wezterm.action_callback(function(_, _, line)
				if not line or line == "" then
					return
				end

				local old = wezterm.mux.get_active_workspace()
				if old == line then
					return
				end

				wezterm.mux.rename_workspace(old, line)
				M.remove_workspace_from_order(old)
				M.touch_workspace_order(line)
			end),
		})
	end
end

return Module
