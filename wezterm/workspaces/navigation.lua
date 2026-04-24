local Module = {}

-- Open, focus, and close workspace windows.
function Module.attach(M, ctx)
	local wezterm = ctx.wezterm
	local constants = ctx.constants

	function M.close_loaded_workspace(workspace_name)
		if not workspace_name or workspace_name == "" or workspace_name == constants.DEFAULT_WORKSPACE then
			return
		end

		if wezterm.mux.get_active_workspace() == workspace_name then
			wezterm.mux.set_active_workspace(constants.DEFAULT_WORKSPACE)
		end

		for _, mux_win in ipairs(wezterm.mux.all_windows()) do
			if mux_win:get_workspace() == workspace_name then
				pcall(function()
					local gui_win = mux_win:gui_window()
					if gui_win then
						gui_win:close()
					end
				end)
			end
		end
	end

	function M.focus_other_gui_window(closing_workspace)
		local excluded_workspaces = { [closing_workspace] = true }
		M.sync_workspace_order(excluded_workspaces)

		for i = #ctx.state.workspace_order, 1, -1 do
			local workspace_name = ctx.state.workspace_order[i]
			if workspace_name ~= closing_workspace then
				for _, mux_win in ipairs(wezterm.mux.all_windows()) do
					if mux_win:get_workspace() == workspace_name then
						local ok = pcall(function()
							local gui_win = mux_win:gui_window()
							if gui_win then
								gui_win:focus()
								wezterm.mux.set_active_workspace(workspace_name)
							end
						end)
						if ok then
							return true
						end
					end
				end
			end
		end

		return false
	end

	function M.open_or_focus_workspace(workspace_name)
		if not workspace_name or workspace_name == "" then
			return false
		end

		for _, mux_win in ipairs(wezterm.mux.all_windows()) do
			if mux_win:get_workspace() == workspace_name then
				local ok = pcall(function()
					local gui_win = mux_win:gui_window()
					if gui_win then
						gui_win:focus()
						wezterm.mux.set_active_workspace(workspace_name)
					end
				end)
				if ok then
					return true
				end
			end
		end

		local ok = pcall(function()
			local _, _, mux_win = wezterm.mux.spawn_window({ workspace = workspace_name })
			local gui_win = mux_win and mux_win:gui_window()
			if gui_win then
				gui_win:focus()
			end
			wezterm.mux.set_active_workspace(workspace_name)
		end)

		return ok
	end
end

return Module
