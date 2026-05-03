local helpers = require("wezterm.helpers")

local M = {}

local function get_battery_text(wezterm)
	local ok, batteries = pcall(wezterm.battery_info)
	if not ok or type(batteries) ~= "table" or not batteries[1] then
		return nil
	end

	local charge = batteries[1].state_of_charge
	if type(charge) ~= "number" then
		return nil
	end

	return tostring(math.floor((charge * 100) + 0.5)) .. "%"
end

-- Register WezTerm event handlers.
function M.register(wezterm, workspaces, constants)
	wezterm.on("update-status", function(window, pane)
		workspaces.start_periodic_autosave()

		local stat = window:active_workspace()
		workspaces.touch_workspace_order(stat)
		workspaces.sync_workspace_order()
		if stat ~= constants.DEFAULT_WORKSPACE then
			workspaces.schedule_workspace_save(stat, 1.0)
		end

		local stat_color = constants.custom_colors.red
		if window:active_key_table() then
			stat = window:active_key_table()
			stat_color = constants.custom_colors.cyan
		end
		if window:leader_is_active() then
			stat = "LDR"
			stat_color = constants.custom_colors.magenta
		end

		local cwd_uri = pane:get_current_working_dir()
		local cwd = cwd_uri and helpers.basename(cwd_uri.file_path) or ""
		local cmd = helpers.basename(pane:get_foreground_process_name())
		local time = wezterm.strftime("%H:%M")
		local battery = get_battery_text(wezterm)

		window:set_left_status(wezterm.format({
			{ Foreground = { Color = stat_color } },
			{ Text = "  " },
			{ Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
			{ Text = " |" },
		}))

		local right_status = {
			{ Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
			{ Text = " | " },
			{ Foreground = { Color = constants.custom_colors.yellow } },
			{ Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
			{ Text = " | " },
			{ Foreground = { Color = constants.custom_colors.cyan } },
			{ Text = wezterm.nerdfonts.md_clock .. "  " .. time },
		}

		if battery then
			table.insert(right_status, { Text = " | " })
			table.insert(right_status, { Foreground = { Color = constants.custom_colors.green } })
			table.insert(right_status, { Text = wezterm.nerdfonts.md_battery .. "  " .. battery })
		end

		table.insert(right_status, { Text = "  " })
		window:set_right_status(wezterm.format(right_status))
	end)

	wezterm.on("window-close-requested", function(window)
		workspaces.autosave_non_default_workspaces()

		local current_workspace = window:active_workspace()
		workspaces.remove_workspace_from_order(current_workspace)
		workspaces.focus_other_gui_window(current_workspace)
	end)
end

return M
