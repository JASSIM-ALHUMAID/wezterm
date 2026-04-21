local wezterm = require("wezterm")
local act = wezterm.action

local DEFAULT_WORKSPACE = "main"
local HOME = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
local APPDATA = os.getenv("APPDATA") or (HOME .. "\\AppData\\Roaming")
local CONFIG_DIR = HOME .. "\\.config\\wezterm"
local STATE_DIR = CONFIG_DIR .. "\\state\\"

local target = wezterm.target_triple
local is_windows = target:find("windows") ~= nil
local is_linux = target:find("linux") ~= nil
local is_darwin = target:find("darwin") ~= nil

package.path = table.concat({
	package.path,
	APPDATA .. "\\wezterm\\plugins\\httpssCssZssZsgithubsDscomsZsMLFlexersZsresurrectsDswezterm\\plugin\\?.lua",
	APPDATA .. "\\wezterm\\plugins\\httpssCssZssZsgithubsDscomsZsMLFlexersZsresurrectsDswezterm\\plugin\\?\\init.lua",
}, ";")

local resurrect = {
	workspace_state = require("resurrect.workspace_state"),
	window_state = require("resurrect.window_state"),
	state_manager = require("resurrect.state_manager"),
}

resurrect.state_manager.save_state_dir = STATE_DIR

local pending_workspace_saves = {}
local periodic_autosave_started = false

local custom_colors = {
	red = "#D06F79",
	cyan = "#88C0D0",
	magenta = "#B48EAD",
	yellow = "#EBCB8B",
}

local function config_builder()
	return wezterm.config_builder and wezterm.config_builder() or {}
end

local function send_line(text)
	return act.SendString(text .. "\r")
end

local function shell_quote_pwsh(arg)
	arg = tostring(arg or ""):gsub("'", "''")
	return "'" .. arg .. "'"
end

local function basename(path)
	return (tostring(path or ""):gsub("[\\/]+$", ""):match("([^\\/]+)$")) or ""
end

local function get_saved_workspace_file_path(workspace_name)
	return STATE_DIR .. "workspace\\" .. workspace_name .. ".json"
end

local function delete_saved_workspace_file(workspace_name)
	return os.remove(get_saved_workspace_file_path(workspace_name))
end

local function get_default_prog()
	if is_windows then
		return { "pwsh.exe", "-NoLogo" }
	end

	if is_linux then
		return { os.getenv("SHELL") or "/bin/bash", "-l" }
	end

	if is_darwin then
		return { os.getenv("SHELL") or "/bin/zsh", "-l" }
	end

	return { "/bin/sh" }
end

local function restore_process_or_text(pane_tree)
	local pane = pane_tree.pane
	local process = pane_tree.process
	local argv = process and process.argv

	if pane_tree.alt_screen_active and argv and #argv > 0 then
		if is_windows then
			local parts = {}
			for _, arg in ipairs(argv) do
				table.insert(parts, shell_quote_pwsh(arg))
			end
			pane:send_text("& " .. table.concat(parts, " ") .. "\r")
		else
			pane:send_text(wezterm.shell_join_args(argv) .. "\r")
		end
	elseif pane_tree.text then
		pane:inject_output(pane_tree.text:gsub("%s+$", ""))
	end
end

local function close_loaded_workspace(workspace_name)
	if not workspace_name or workspace_name == "" or workspace_name == DEFAULT_WORKSPACE then
		return
	end

	if wezterm.mux.get_active_workspace() == workspace_name then
		wezterm.mux.set_active_workspace(DEFAULT_WORKSPACE)
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

local function get_workspace_state_by_name(workspace_name)
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

local function get_mux_workspace_names()
	local seen = {}
	local names = {}

	for _, mux_win in ipairs(wezterm.mux.all_windows()) do
		local workspace = mux_win:get_workspace()
		if workspace and workspace ~= "" and not seen[workspace] then
			seen[workspace] = true
			table.insert(names, workspace)
		end
	end

	table.sort(names)
	return names
end

local function save_workspace_by_name(workspace_name)
	if not workspace_name or workspace_name == "" then
		return false
	end

	local state = get_workspace_state_by_name(workspace_name)
	if not state.window_states or #state.window_states == 0 then
		return false
	end

	resurrect.state_manager.save_state(state)
	return true
end

local function schedule_workspace_save(workspace_name, delay)
	if not workspace_name or workspace_name == "" or workspace_name == DEFAULT_WORKSPACE then
		return
	end

	if pending_workspace_saves[workspace_name] then
		return
	end

	pending_workspace_saves[workspace_name] = true
	wezterm.time.call_after(delay or 1.0, function()
		pending_workspace_saves[workspace_name] = nil
		save_workspace_by_name(workspace_name)
	end)
end

local function autosave_non_default_workspaces()
	for _, workspace_name in ipairs(get_mux_workspace_names()) do
		if workspace_name ~= DEFAULT_WORKSPACE then
			save_workspace_by_name(workspace_name)
		end
	end
end

local function start_periodic_autosave()
	if periodic_autosave_started then
		return
	end

	periodic_autosave_started = true
	local function tick()
		autosave_non_default_workspaces()
		wezterm.time.call_after(30, tick)
	end
	wezterm.time.call_after(30, tick)
end

local function save_current_workspace(window)
	local state = resurrect.workspace_state.get_workspace_state()
	resurrect.state_manager.save_state(state)
	window:toast_notification("WezTerm", "Workspace saved: " .. state.workspace, nil, 3000)
end

local function get_saved_workspace_names()
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

local function restore_workspace_by_name(workspace_name)
	local state = resurrect.state_manager.load_state(workspace_name, "workspace")
	if not state or not state.window_states or #state.window_states == 0 then
		return false
	end

	resurrect.workspace_state.restore_workspace(state, {
		spawn_in_workspace = true,
		relative = true,
		restore_text = true,
		on_pane_restore = restore_process_or_text,
	})
	return true
end

local function switch_workspace(window, pane)
	local loaded_names = get_mux_workspace_names()
	local loaded = {}
	local choices = {}

	for _, name in ipairs(loaded_names) do
		loaded[name] = true
		table.insert(choices, { id = name, label = name .. "  [loaded]" })
	end

	local saved_names, err = get_saved_workspace_names()
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

	window:perform_action(act.InputSelector({
		title = "Switch workspace",
		description = "Select workspace to switch or lazy-load",
		fuzzy_description = "Search workspace: ",
		fuzzy = true,
		choices = choices,
		action = wezterm.action_callback(function(inner_window, inner_pane, id)
			if not id then
				return
			end

			if not loaded[id] and not restore_workspace_by_name(id) then
				inner_window:toast_notification("WezTerm", "Workspace load failed: " .. id, nil, 5000)
				return
			end

			inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
		end),
	}), pane)
end

local function delete_workspace(window, pane)
	local names, err = get_saved_workspace_names()
	if not names then
		window:toast_notification("WezTerm", "Workspace list failed: " .. tostring(err), nil, 5000)
		return
	end

	local choices = {}
	for _, name in ipairs(names) do
		if name ~= DEFAULT_WORKSPACE then
			table.insert(choices, { id = name, label = name })
		end
	end

	if #choices == 0 then
		window:toast_notification("WezTerm", "No saved non-main workspaces found", nil, 3000)
		return
	end

	window:perform_action(act.InputSelector({
		title = "Delete workspace",
		description = "Select saved workspace to delete and unload",
		fuzzy_description = "Delete workspace: ",
		fuzzy = true,
		choices = choices,
		action = wezterm.action_callback(function(inner_window, inner_pane, id)
			if not id then
				return
			end

			close_loaded_workspace(id)

			local ok, remove_err = delete_saved_workspace_file(id)
			if not ok then
				inner_window:toast_notification("WezTerm", "Delete failed: " .. tostring(remove_err), nil, 5000)
				return
			end

			inner_window:perform_action(act.SwitchToWorkspace({ name = DEFAULT_WORKSPACE }), inner_pane)
		end),
	}), pane)
end

local function quick_cd(path)
	return send_line('cd "' .. path .. '"')
end

local function rename_tab_title()
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

local function rename_workspace()
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
			if old ~= DEFAULT_WORKSPACE then
				delete_saved_workspace_file(old)
			end
			schedule_workspace_save(line, 0.2)
		end),
	})
end

local config = config_builder()

config.default_prog = get_default_prog()
config.default_workspace = DEFAULT_WORKSPACE
config.color_scheme = "Afterglow"
config.font = wezterm.font_with_fallback({
	{ family = "UbuntuMono Nerd Font", scale = 1.35 },
})
config.window_background_opacity = 0.8
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.quit_when_all_windows_are_closed = true
config.scrollback_lines = 3000
config.default_cursor_style = "BlinkingBar"
config.automatically_reload_config = false
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = true
config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = {
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = ";", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "S", mods = "LEADER|SHIFT", action = wezterm.action_callback(save_current_workspace) },
	{ key = "L", mods = "LEADER|SHIFT", action = wezterm.action_callback(switch_workspace) },
	{ key = "D", mods = "LEADER|SHIFT", action = wezterm.action_callback(delete_workspace) },
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = ",", mods = "LEADER", action = rename_tab_title() },
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },
	{ key = "]", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "[", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "phys:Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "!", mods = "LEADER|SHIFT", action = wezterm.action_callback(function(_, pane)
		pane:move_to_new_tab()
	end) },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ key = "F", mods = "LEADER|SHIFT", action = act.ToggleFullScreen },
	{ key = "R", mods = "LEADER|SHIFT", action = rename_workspace() },
	{ key = "u", mods = "LEADER", action = quick_cd(HOME .. "/UNI/") },
	{ key = "i", mods = "LEADER", action = quick_cd(HOME .. "/.config") },
	{ key = "o", mods = "LEADER", action = quick_cd(HOME .. "/AppData/Local/nvim") },
	{ key = "v", mods = "LEADER", action = send_line("nvim .") },
	{ key = "e", mods = "LEADER", action = send_line("yazi") },
	{ key = "f", mods = "LEADER", action = quick_cd("G:/") },
	{ key = "b", mods = "LEADER", action = send_line(HOME .. "/Downloads/Development/btop4win/btop4win.exe") },
}

for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	move_tab = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

wezterm.on("update-status", function(window, pane)
	start_periodic_autosave()

	local stat = window:active_workspace()
	if stat ~= DEFAULT_WORKSPACE then
		schedule_workspace_save(stat, 1.0)
	end

	local stat_color = custom_colors.red
	if window:active_key_table() then
		stat = window:active_key_table()
		stat_color = custom_colors.cyan
	end
	if window:leader_is_active() then
		stat = "LDR"
		stat_color = custom_colors.magenta
	end

	local cwd_uri = pane:get_current_working_dir()
	local cwd = cwd_uri and basename(cwd_uri.file_path) or ""
	local cmd = basename(pane:get_foreground_process_name())

	window:set_left_status(wezterm.format({
		{ Foreground = { Color = stat_color } },
		{ Text = "  " },
		{ Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
		{ Text = " |" },
	}))

	window:set_right_status(wezterm.format({
		{ Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
		{ Text = " | " },
		{ Foreground = { Color = custom_colors.yellow } },
		{ Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
		{ Text = "  " },
	}))
end)

wezterm.on("window-close-requested", function()
	autosave_non_default_workspaces()
end)

return config
