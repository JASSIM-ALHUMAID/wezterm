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
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 3000
config.default_workspace = "main"
config.default_cursor_style = "BlinkingBar"

config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

config.automatically_reload_config = false

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = {
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = ";", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
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
	{
		key = "!",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			local tab, window = pane:move_to_new_tab()
		end),
	},
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ mods = "LEADER|SHIFT", key = "F", action = act.ToggleFullScreen },
	{ mods = "LEADER", key = "u", action = wezterm.action({ SendString = 'cd "C:/Users/jassi/UNI/"\r' }) },
	{
		mods = "LEADER|SHIFT",
		key = "R",
		action = act.PromptInputLine({
			description = "Rename workspace:",
			action = wezterm.action_callback(function(window, pane, line)
				if line and line ~= "" then
					local old = wezterm.mux.get_active_workspace()
					wezterm.mux.rename_workspace(old, line)
				end
			end),
		}),
	},
	{ mods = "LEADER", key = "i", action = wezterm.action({ SendString = 'cd "C:/Users/jassi/.config"\r' }) },
	{ mods = "LEADER", key = "o", action = wezterm.action({ SendString = 'cd "C:/Users/jassi/AppData/Local/nvim"\r' }) },
	{ mods = "LEADER", key = "v", action = wezterm.action({ SendString = "nvim . \r" }) },
	{ mods = "LEADER", key = "e", action = wezterm.action({ SendString = "yazi  \r" }) },
	{ mods = "LEADER", key = "f", action = wezterm.action({ SendString = 'cd "G:/"\r' }) },
	{ mods = "LEADER", key = "b", action = wezterm.action({ SendString = "C:/Users/jassi/Downloads/Development/btop4win/btop4win.exe \r" }) },
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

config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = true
wezterm.on("update-status", function(window, pane)
	local stat = window:active_workspace()
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
		return string.gsub(s, "(.*[//])(.*)", "%2")
	end

	local cwd = pane:get_current_working_dir()
	if cwd then
		cwd = basename(cwd.file_path)
	else
		cwd = ""
	end

	local cmd = pane:get_foreground_process_name()
	cmd = cmd and basename(cmd) or ""

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

return config
