--- wezterm.lua
--- $ figlet -f small Wezterm
--- __      __      _
--- \ \    / /__ __| |_ ___ _ _ _ __
---  \ \/\/ / -_)_ /  _/ -_) '_| '  \
---   \_/\_/\___/__|\__\___|_| |_|_|_|
---
--- My Wezterm config file for Windows

local wezterm = require("wezterm")
local act = wezterm.action

local appdata = os.getenv("APPDATA") or ((os.getenv("USERPROFILE") or "") .. "\\AppData\\Roaming")
local resurrect_plugin_dir = appdata
	.. "\\wezterm\\plugins\\httpssCssZssZsgithubsDscomsZsMLFlexersZsresurrectsDswezterm"

package.path = table.concat({
	package.path,
	resurrect_plugin_dir .. "\\plugin\\?.lua",
	resurrect_plugin_dir .. "\\plugin\\?\\init.lua",
}, ";")

local resurrect = {
	workspace_state = require("resurrect.workspace_state"),
	window_state = require("resurrect.window_state"),
	tab_state = require("resurrect.tab_state"),
	state_manager = require("resurrect.state_manager"),
}

local DEFAULT_WORKSPACE = "main"
local pending_workspace_saves = {}
local periodic_autosave_started = false

resurrect.state_manager.save_state_dir = "C:\\Users\\jassi\\.config\\wezterm\\state\\"

local function get_saved_workspace_file_path(workspace_name)
	return resurrect.state_manager.save_state_dir .. "workspace\\" .. workspace_name .. ".json"
end

local function delete_saved_workspace_file(workspace_name)
	return os.remove(get_saved_workspace_file_path(workspace_name))
end

local function trigger_windows_wezterm_cleanup()
	if not wezterm.target_triple:find("windows") then
		return
	end

	local cleanup_script = table.concat({
		"Start-Sleep -Seconds 2",
		"taskkill /IM wezterm-gui.exe /T /F *> $null",
	}, "; ")

	wezterm.run_child_process({
		"pwsh.exe",
		"-NoProfile",
		"-WindowStyle",
		"Hidden",
		"-Command",
		"Start-Process pwsh.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-Command','"
			.. cleanup_script
			.. "'",
	})
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
			local ok = pcall(function()
				local gui_win = mux_win:gui_window()
				if gui_win then
					gui_win:close()
				end
			end)
		end
	end
	wezterm.mux.set_active_workspace(DEFAULT_WORKSPACE)
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

local function save_current_workspace(window, pane)
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
		on_pane_restore = resurrect.tab_state.default_on_pane_restore,
	})
	return true
end

local function switch_workspace(window, pane)
	local loaded = {}
	for _, name in ipairs(get_mux_workspace_names()) do
		loaded[name] = true
	end

	local choices = {}
	for _, name in ipairs(get_mux_workspace_names()) do
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
		action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
			if not id then
				return
			end

			if not loaded[id] then
				local ok = restore_workspace_by_name(id)
				if not ok then
					inner_window:toast_notification("WezTerm", "Workspace load failed: " .. id, nil, 5000)
					return
				end
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

	if #names == 0 then
		window:toast_notification("WezTerm", "No saved workspaces found", nil, 3000)
		return
	end

	local choices = {}
	for _, name in ipairs(names) do
		table.insert(choices, { id = name, label = name })
	end

	window:perform_action(act.InputSelector({
		title = "Delete workspace",
		description = "Select saved workspace to delete and unload",
		fuzzy_description = "Delete workspace: ",
		fuzzy = true,
		choices = choices,
		action = wezterm.action_callback(function(inner_window, inner_pane, id, _)
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
			inner_window:toast_notification("WezTerm", "Workspace deleted: " .. id, nil, 3000)
		end),
	}), pane)
end

local config = {}
-- Use config builder object if possible
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Helpers to detect OS
local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_linux = wezterm.target_triple:find("linux") ~= nil
local is_darwin = wezterm.target_triple:find("darwin") ~= nil

-- Decide shell per OS
local shell_path
local shell_args = {}

if is_windows then
	-- Windows: PowerShell 7 (adjust path if needed)
	shell_path = "pwsh.exe"
	shell_args = { "-NoLogo" }
elseif is_linux then
	-- Linux: use the user's login shell
	shell_path = os.getenv("SHELL") or "/bin/bash"
	shell_args = { "-l" }
elseif is_darwin then
	-- macOS example
	shell_path = os.getenv("SHELL") or "/bin/zsh"
	shell_args = { "-l" }
else
	-- Fallback
	shell_path = "/bin/sh"
end

config.default_prog = { shell_path, table.unpack(shell_args) }

config.color_scheme = "Afterglow"
local custom_colors = {
	red = "#D06F79", -- Tokyonight: "#F7768e"
	cyan = "#88C0D0", -- Tokyonight: "#7DCFFF"
	magenta = "#B48EAD", -- Tokyonight: "#BB9AF7"
	yellow = "#EBCB8B", -- Tokyonight: "#E0AF68"
}

config.font = wezterm.font_with_fallback({
	{ family = "UbuntuMono Nerd Font", scale = 1.35 },
})
config.window_background_opacity = 0.8
-- macos_window_background_blur is not supported on Windows, so it's removed
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.quit_when_all_windows_are_closed = true
config.scrollback_lines = 3000
config.default_workspace = DEFAULT_WORKSPACE
config.default_cursor_style = "BlinkingBar"

-- Dim inactive panes
config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

config.automatically_reload_config = false

-- Keys
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = {
	-- Send C-a when pressing C-a twice
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = ";", mods = "LEADER", action = act.ActivateCommandPalette },

	-- Workspace (similar to session in Tmux)
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{
		key = "S",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(save_current_workspace),
	},
	{
		key = "L",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(switch_workspace),
	},
	{
		key = "D",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(delete_workspace),
	},

	-- Tab (similar to window in Tmux)
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Renaming Tab Title...:" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	-- Key table for moving tabs around
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },

	-- Pane
	{ key = "]", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "[", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "phys:Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{
		key = "!",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			local tab, window = pane:move_to_new_tab()
		end),
	},
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- z somePath
	-- Fullscreen
	{
		mods = "LEADER|SHIFT",
		key = "F",
		action = act.ToggleFullScreen,
	},
	{
		mods = "LEADER",
		key = "u",
		action = wezterm.action({
			SendString = 'cd "C:/Users/jassi/UNI/"\r',
		}),
	},
	-- Rename workspace
	{
		mods = "LEADER|SHIFT",
		key = "R",
		action = act.PromptInputLine({
			description = "Rename workspace:",
			action = wezterm.action_callback(function(window, pane, line)
				if line and line ~= "" then
					local old = wezterm.mux.get_active_workspace()
					wezterm.mux.rename_workspace(old, line)
					if old ~= DEFAULT_WORKSPACE then
						delete_saved_workspace_file(old)
					end
					schedule_workspace_save(line, 0.2)
				end
			end),
		}),
	},
	{ mods = "LEADER", key = "i", action = wezterm.action({
		SendString = 'cd "C:/Users/jassi/.config"\r',
	}) },
	{
		mods = "LEADER",
		key = "o",
		action = wezterm.action({
			SendString = 'cd "C:/Users/jassi/AppData/Local/nvim"\r',
		}),
	},
	{ mods = "LEADER", key = "v", action = wezterm.action({
		SendString = "nvim . \r",
	}) },
	{
		mods = "LEADER",
		key = "e",
		action = wezterm.action({
			SendString = "yazi  \r",
		}),
	},
	{
		mods = "LEADER",
		key = "f",
		action = wezterm.action({
			SendString = 'cd "G:/"\r',
		}),
	},
	{
		mods = "LEADER",
		key = "b",
		action = wezterm.action({
			SendString = "C:/Users/jassi/Downloads/Development/btop4win/btop4win.exe \r",
		}),
	},
}

-- Tab navigation by index
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

-- Tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = true
wezterm.on("update-status", function(window, pane)
	start_periodic_autosave()

	-- Workspace name
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

	local basename = function(s)
		-- Adjust for Windows paths (replace forward slashes with backslashes)
		return string.gsub(s, "(.*[//])(.*)", "%2")
	end

	-- Current working directory
	local cwd = pane:get_current_working_dir()
	if cwd then
		cwd = basename(cwd.file_path) -- URL object for newer WezTerm versions
	else
		cwd = ""
	end

	-- Current command
	local cmd = pane:get_foreground_process_name()
	cmd = cmd and basename(cmd) or ""

	-- Left status
	window:set_left_status(wezterm.format({
		{ Foreground = { Color = stat_color } },
		{ Text = "  " },
		{ Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
		{ Text = " |" },
	}))

	-- Right status
	window:set_right_status(wezterm.format({
		{ Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
		{ Text = " | " },
		{ Foreground = { Color = custom_colors.yellow } },
		{ Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
		{ Text = "  " },
	}))
end)

wezterm.on("window-close-requested", function(window, pane)
	autosave_non_default_workspaces()
	trigger_windows_wezterm_cleanup()
	window:perform_action(act.QuitApplication, pane)
end)

-- Commented-out appearance settings for screenshots
--[[
config.enable_tab_bar = false
config.window_padding = {
  left = "0.5cell",
  right = "0.5cell",
  top = "0.5cell",
  bottom = "0cell",
}
--]]

-- =============================================================================
-- SHORTCUTS LIST
-- =============================================================================
-- Leader key: Ctrl+a (press twice within 2s for literal Ctrl+a)
--
-- === General ===
-- Ctrl+a a          Send literal Ctrl+a
-- Ctrl+a y          Activate copy mode
-- Ctrl+a ;          Command palette
-- Ctrl+a s          Workspace launcher
-- Ctrl+Shift+a S    Save current workspace
-- Ctrl+Shift+a L    Switch or lazy-load workspace
-- Ctrl+Shift+a D    Delete saved workspace snapshot
-- Ctrl+Shift+a F    Toggle fullscreen
-- Ctrl+Shift+a R    Rename workspace
--
-- === Tab ===
-- Ctrl+a w          Tab navigator
-- Ctrl+a c          New tab
-- Ctrl+a p          Previous tab
-- Ctrl+a n          Next tab
-- Ctrl+a ,          Rename tab title
-- Ctrl+a .          Move tab mode (then h/j/k/l to swap)
-- Ctrl+a 1-9        Jump to tab by index
--
-- === Pane ===
-- Ctrl+a ]          Split vertical
-- Ctrl+a [           Split horizontal
-- Ctrl+a h/j/k/l    Navigate panes (vim-style)
-- Ctrl+a Space     Rotate panes
-- Ctrl+a z          Toggle pane zoom
-- Ctrl+a x          Close pane
-- Ctrl+Shift+a !   Move pane to new tab
-- Ctrl+a r          Resize pane mode (then h/j/k/l, Esc/Enter to exit)
--
-- === Quick Actions ===
-- Ctrl+a u          cd in UNI
-- Ctrl+a i          cd to .config
-- Ctrl+a o          cd to nvim config
-- Ctrl+a v          nvim
-- Ctrl+a e          cd in cwd
-- Ctrl+a f          cd in G:/
-- Ctrl+a b          btop
--
-- === Key Tables (after activation) ===
-- resize_pane: h/j/k/l to resize, Esc/Enter to exit
-- move_tab:    h/j/k/l to swap tabs, Esc/Enter to exit
-- =============================================================================

return config
