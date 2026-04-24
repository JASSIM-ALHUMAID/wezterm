local Module = {}

-- User-facing workspace prompts and selectors.
function Module.attach(M, ctx)
	local wezterm = ctx.wezterm
	local act = ctx.act
	local constants = ctx.constants
	local helpers = ctx.helpers

	function M.build_bulk_delete_choices(names, selected_names, anchor_name)
		local selected_lookup = {}
		local choices = {
			{ id = "__done__", label = "Done deleting selected" },
		}
		local remaining_names = {}

		for _, name in ipairs(selected_names) do
			selected_lookup[name] = true
			table.insert(choices, { id = "__selected__" .. name, label = "Selected: " .. name })
		end

		for _, name in ipairs(names) do
			if name ~= constants.DEFAULT_WORKSPACE and not selected_lookup[name] then
				table.insert(remaining_names, name)
			end
		end

		if anchor_name then
			local anchor_index
			for i, name in ipairs(remaining_names) do
				if name > anchor_name then
					anchor_index = i
					break
				end
			end

			if anchor_index and anchor_index > 1 then
				local reordered = {}
				for i = anchor_index, #remaining_names do
					table.insert(reordered, remaining_names[i])
				end
				for i = 1, anchor_index - 1 do
					table.insert(reordered, remaining_names[i])
				end
				remaining_names = reordered
			end
		end

		for _, name in ipairs(remaining_names) do
			table.insert(choices, { id = name, label = name })
		end

		return choices
	end

	function M.switch_workspace(window, pane)
		local loaded_names = M.get_mux_workspace_names()
		local loaded = {}
		local choices = {}

		for _, name in ipairs(loaded_names) do
			loaded[name] = true
			table.insert(choices, { id = name, label = name .. "  [loaded]" })
		end

		local saved_names, err = M.get_saved_workspace_names()
		if not saved_names then
			window:toast_notification("WezTerm", "Workspace list failed: " .. tostring(err), nil, 5000)
			return
		end

		for _, name in ipairs(saved_names) do
			if not loaded[name] then
				table.insert(choices, { id = name, label = name .. "  [saved]" })
			end
		end

		if #choices == 0 then
			window:toast_notification("WezTerm", "No workspaces found", nil, 3000)
			return
		end

		window:perform_action(
			act.InputSelector({
				title = "Switch workspace",
				description = "Select workspace to switch or lazy-load",
				fuzzy_description = "Search workspace: ",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end

					if not loaded[id] and not M.restore_workspace_by_name(id) then
						inner_window:toast_notification("WezTerm", "Workspace load failed: " .. id, nil, 5000)
						return
					end

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
		local loaded = {}
		local choices = {
			{ id = "__create__", label = "+ Create workspace" },
		}

		for _, name in ipairs(loaded_names) do
			loaded[name] = true
			table.insert(choices, { id = name, label = name .. "  [loaded]" })
		end

		local saved_names, err = M.get_saved_workspace_names()
		if not saved_names then
			window:toast_notification("WezTerm", "Workspace list failed: " .. tostring(err), nil, 5000)
			return
		end

		for _, name in ipairs(saved_names) do
			if not loaded[name] then
				table.insert(choices, { id = name, label = name .. "  [saved]" })
			end
		end

		window:perform_action(
			act.InputSelector({
				title = "Workspace",
				description = "Switch, load, or create workspace",
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

					if not loaded[id] and not M.restore_workspace_by_name(id) then
						inner_window:toast_notification("WezTerm", "Workspace load failed: " .. id, nil, 5000)
						return
					end

					M.touch_workspace_order(id)
					inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
				end),
			}),
			pane
		)
	end

	function M.delete_workspace(window, pane)
		local names, err = M.get_saved_workspace_names()
		if not names then
			window:toast_notification("WezTerm", "Workspace list failed: " .. tostring(err), nil, 5000)
			return
		end

		local function delete_selected_workspaces(selected_names, inner_window, inner_pane)
			local deleted = 0
			for _, name in ipairs(selected_names) do
				local ok = M.delete_saved_workspace(name)
				if ok then
					deleted = deleted + 1
				end
			end

			if deleted > 0 then
				inner_window:perform_action(act.SwitchToWorkspace({ name = constants.DEFAULT_WORKSPACE }), inner_pane)
			else
				inner_window:toast_notification("WezTerm", "No workspaces deleted", nil, 3000)
			end
		end

		local function prompt_bulk_delete(inner_window, inner_pane, selected_names, anchor_name)
			selected_names = selected_names or {}

			inner_window:perform_action(
				act.InputSelector({
					title = "Delete multiple workspaces",
					description = anchor_name and ("Continue near: " .. anchor_name)
						or "Pick workspaces one by one, then choose done",
					fuzzy_description = "Select workspace: ",
					fuzzy = true,
					choices = M.build_bulk_delete_choices(names, selected_names, anchor_name),
					action = wezterm.action_callback(function(next_window, next_pane, id)
						if not id then
							return
						end

						if id == "__done__" then
							delete_selected_workspaces(selected_names, next_window, next_pane)
							return
						end

						if id:sub(1, 12) == "__selected__" then
							prompt_bulk_delete(next_window, next_pane, selected_names, anchor_name)
							return
						end

						table.insert(selected_names, id)
						prompt_bulk_delete(next_window, next_pane, selected_names, id)
					end),
				}),
				inner_pane
			)
		end

		local choices = {
			{ id = "__bulk_delete__", label = "+ Delete multiple workspaces" },
		}
		for _, name in ipairs(names) do
			if name ~= constants.DEFAULT_WORKSPACE then
				table.insert(choices, { id = name, label = name })
			end
		end

		if #choices == 0 then
			window:toast_notification("WezTerm", "No saved non-main workspaces found", nil, 3000)
			return
		end

		window:perform_action(
			act.InputSelector({
				title = "Delete workspace",
				description = "Select one workspace or choose bulk delete",
				fuzzy_description = "Delete workspace: ",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end

					if id == "__bulk_delete__" then
						prompt_bulk_delete(inner_window, inner_pane, {})
						return
					end

					local ok, remove_err = M.delete_saved_workspace(id)
					if not ok then
						inner_window:toast_notification("WezTerm", "Delete failed: " .. tostring(remove_err), nil, 5000)
						return
					end

					inner_window:perform_action(act.SwitchToWorkspace({ name = constants.DEFAULT_WORKSPACE }), inner_pane)
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
				if old ~= constants.DEFAULT_WORKSPACE then
					helpers.delete_saved_workspace_file(constants, old)
				end
				M.schedule_workspace_save(line, 0.2)
			end),
		})
	end
end

return Module
