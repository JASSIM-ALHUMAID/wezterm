local Module = {}

-- Save, load, and autosave workspace state.
function Module.attach(M, ctx)
	local wezterm = ctx.wezterm
	local constants = ctx.constants
	local helpers = ctx.helpers
	local resurrect = ctx.resurrect
	local state = ctx.state

	function M.restore_process_or_text(pane_tree)
		local pane = pane_tree.pane
		local process = pane_tree.process
		local argv = process and process.argv

		if pane_tree.alt_screen_active and argv and #argv > 0 then
			if constants.is_windows then
				local parts = {}
				for _, arg in ipairs(argv) do
					table.insert(parts, helpers.shell_quote_pwsh(arg))
				end
				pane:send_text("& " .. table.concat(parts, " ") .. "\r")
			else
				pane:send_text(wezterm.shell_join_args(argv) .. "\r")
			end
		elseif pane_tree.text then
			pane:inject_output(pane_tree.text:gsub("%s+$", ""))
		end
	end

	function M.get_workspace_state_by_name(workspace_name)
		local workspace_state = {
			workspace = workspace_name,
			window_states = {},
		}

		for _, mux_win in ipairs(wezterm.mux.all_windows()) do
			if mux_win:get_workspace() == workspace_name then
				table.insert(workspace_state.window_states, resurrect.window_state.get_window_state(mux_win))
			end
		end

		return workspace_state
	end

	function M.delete_saved_workspace(workspace_name)
		M.close_loaded_workspace(workspace_name)

		local ok, remove_err = helpers.delete_saved_workspace_file(constants, workspace_name)
		if ok then
			M.remove_workspace_from_order(workspace_name)
		end

		return ok, remove_err
	end

	function M.save_workspace_by_name(workspace_name)
		if not workspace_name or workspace_name == "" then
			return false
		end

		local current_state = M.get_workspace_state_by_name(workspace_name)
		if not current_state.window_states or #current_state.window_states == 0 then
			return false
		end

		resurrect.state_manager.save_state(current_state)
		return true
	end

	function M.schedule_workspace_save(workspace_name, delay)
		if not workspace_name or workspace_name == "" or workspace_name == constants.DEFAULT_WORKSPACE then
			return
		end

		if state.pending_workspace_saves[workspace_name] then
			return
		end

		state.pending_workspace_saves[workspace_name] = true
		wezterm.time.call_after(delay or 1.0, function()
			state.pending_workspace_saves[workspace_name] = nil
			M.save_workspace_by_name(workspace_name)
		end)
	end

	function M.autosave_non_default_workspaces()
		for _, workspace_name in ipairs(M.get_mux_workspace_names()) do
			if workspace_name ~= constants.DEFAULT_WORKSPACE then
				M.save_workspace_by_name(workspace_name)
			end
		end
	end

	function M.start_periodic_autosave()
		if state.periodic_autosave_started then
			return
		end

		state.periodic_autosave_started = true
		local function tick()
			M.autosave_non_default_workspaces()
			wezterm.time.call_after(30, tick)
		end
		wezterm.time.call_after(30, tick)
	end

	function M.save_current_workspace(window)
		local current_state = resurrect.workspace_state.get_workspace_state()
		resurrect.state_manager.save_state(current_state)
		window:toast_notification("WezTerm", "Workspace saved: " .. current_state.workspace, nil, 3000)
	end

	function M.get_saved_workspace_names()
		local workspace_dir = resurrect.state_manager.save_state_dir .. "workspace"
		local success, stdout, stderr = wezterm.run_child_process({
			"pwsh.exe",
			"-NoProfile",
			"-Command",
			"@(Get-ChildItem -Path '"
				.. workspace_dir
				.. "' -Filter '*.json' -File | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty BaseName) | ConvertTo-Json -Compress",
		})

		if not success then
			return nil, stderr
		end

		if not stdout or stdout == "" then
			return {}, nil
		end

		local ok, decoded = pcall(wezterm.json_parse, stdout)
		if not ok then
			return nil, decoded
		end

		if type(decoded) == "string" then
			return { decoded }, nil
		end

		return decoded or {}, nil
	end

	function M.restore_workspace_by_name(workspace_name)
		local current_state = resurrect.state_manager.load_state(workspace_name, "workspace")
		if not current_state or not current_state.window_states or #current_state.window_states == 0 then
			return false
		end

		resurrect.workspace_state.restore_workspace(current_state, {
			spawn_in_workspace = true,
			relative = true,
			restore_text = true,
			on_pane_restore = M.restore_process_or_text,
		})
		return true
	end
end

return Module
