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
			window:toast_notification("WezTerm", "No workspaces found", nil, 2000)
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

	local function toast_saved(window, name, saved)
		window:toast_notification(
			"WezTerm",
			saved and ('Saved workspace "' .. name .. '"') or ('Could not save workspace "' .. name .. '"'),
			nil,
			2000
		)
	end

	-- Pick a saved workspace and delete its state file (with confirmation).
	function M.delete_workspace_menu(window, pane)
		local saved = M.list_saved_workspaces()
		if #saved == 0 then
			window:toast_notification("WezTerm", "No saved workspaces", nil, 2000)
			return
		end

		local choices = {}
		for _, name in ipairs(saved) do
			table.insert(choices, { id = name, label = name })
		end

		window:perform_action(
			act.InputSelector({
				title = "Delete saved workspace",
				description = "Select a saved workspace to delete",
				fuzzy_description = "Delete: ",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end

					inner_window:perform_action(
						act.InputSelector({
							title = 'Delete "' .. id .. '"?',
							description = "This permanently removes the saved session",
							choices = {
								{ id = "yes", label = "Yes, delete" },
								{ id = "no", label = "Cancel" },
							},
							action = wezterm.action_callback(function(confirm_window, _, confirm)
								if confirm ~= "yes" then
									return
								end
								local deleted = M.delete_workspace_by_name(id)
								confirm_window:toast_notification(
									"WezTerm",
									deleted and ('Deleted "' .. id .. '"') or ('Could not delete "' .. id .. '"'),
									nil,
									2000
								)
							end),
						}),
						inner_pane
					)
				end),
			}),
			pane
		)
	end

	-- Persist the active workspace. The default workspace is unnamed, so prompt
	-- for a name (renaming it) before saving.
	function M.save_workspace(window, pane)
		local name = window:active_workspace()

		if name ~= constants.DEFAULT_WORKSPACE then
			toast_saved(window, name, M.save_workspace_by_name(name))
			return
		end

		window:perform_action(
			act.PromptInputLine({
				description = "Name this workspace to save it:",
				action = wezterm.action_callback(function(inner_window, _, line)
					if not line or line == "" then
						return
					end

					local old = inner_window:active_workspace()
					wezterm.mux.rename_workspace(old, line)
					M.remove_workspace_from_order(old)
					M.touch_workspace_order(line)

					toast_saved(inner_window, line, M.save_workspace_by_name(line))
				end),
			}),
			pane
		)
	end
	-- Save the active workspace to disk, then close its window(s) and switch
	-- to the most recently used loaded workspace (or default if none remain).
	function M.save_and_close_current_workspace(window, pane)
		local name = window:active_workspace()

		local function finalize(name)
			M.save_workspace_by_name(name)

			-- Mirror closing the last pane (see window-close-requested): land on
			-- the most-recently-used other loaded workspace, or quit wezterm if
			-- this was the only one left.
			local fallback = M.get_loaded_fallback_workspace_name(name)

			if not fallback then
				M.remove_workspace_from_order(name)
				window:perform_action(act.QuitApplication, pane)
				return
			end

			-- Switch to the fallback workspace first (this properly materializes
			-- headless mux windows instead of spawning duplicates), then close
			-- the current workspace after a brief delay (see window-close-requested).
			M.remove_workspace_from_order(name)
			M.touch_workspace_order(fallback)
			window:perform_action(act.SwitchToWorkspace({ name = fallback }), pane)
			wezterm.time.call_after(0.1, function()
				M.close_loaded_workspace(name)
			end)
		end

		if name == constants.DEFAULT_WORKSPACE then
			window:perform_action(
				act.PromptInputLine({
					description = "Name this workspace to save and close it:",
					action = wezterm.action_callback(function(inner_window, _, line)
						if not line or line == "" then
							return
						end
						local old = inner_window:active_workspace()
						wezterm.mux.rename_workspace(old, line)
						M.remove_workspace_from_order(old)
						M.touch_workspace_order(line)
						finalize(line)
					end),
				}),
				pane
			)
			return
		end

		finalize(name)
	end
end

return Module
