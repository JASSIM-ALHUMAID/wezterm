local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Shared helper functions.
function M.config_builder()
	return wezterm.config_builder and wezterm.config_builder() or {}
end

function M.send_line(text)
	return act.SendString(text .. "\r")
end

function M.quick_cd(path)
	return M.send_line('cd "' .. path .. '"')
end

function M.shell_quote_pwsh(arg)
	arg = tostring(arg or ""):gsub("'", "''")
	return "'" .. arg .. "'"
end

function M.basename(path)
	return (tostring(path or ""):gsub("[\\/]+$", ""):match("([^\\/]+)$")) or ""
end

-- Windows shells. Fish ships with MSYS2; spawn its exe directly so it inherits
-- the terminal's full Windows PATH (scoop/winget/Program Files tools). NOTE: no
-- `-l` (login) flag on purpose -- msys2's /etc/fish/config.fish sources
-- msys2.fish for login shells, which rebuilds PATH down to msys-only dirs and
-- hides every Windows-side tool (fastfetch, starship, lazygit, ...).
function M.win_fish_prog()
	return { "C:\\msys64\\usr\\bin\\fish.exe", "-i" }
end

function M.win_pwsh_prog()
	return { "pwsh.exe", "-NoLogo" }
end

function M.get_default_prog(constants)
	if constants.is_windows then
		-- pwsh is the startup/default shell: msys2 fish deadlocks as the very
		-- first pane under WezTerm's ConPTY. Fish is available on demand via
		-- LEADER g, the launch menu, and win_fish_prog().
		return M.win_pwsh_prog()
	end

	if constants.is_linux then
		return { os.getenv("SHELL") or "/bin/bash", "-l" }
	end

	if constants.is_darwin then
		return { os.getenv("SHELL") or "/bin/zsh", "-l" }
	end

	return { "/bin/sh" }
end

-- New-tab dropdown / command-palette shell entries (Windows only).
function M.build_launch_menu(constants)
	if not constants.is_windows then
		return {}
	end
	return {
		{ label = "fish (UCRT64)", args = M.win_fish_prog() },
		{ label = "PowerShell", args = M.win_pwsh_prog() },
	}
end

return M
