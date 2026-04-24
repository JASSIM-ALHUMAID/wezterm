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

function M.get_saved_workspace_file_path(constants, workspace_name)
	return constants.STATE_DIR .. "workspace\\" .. workspace_name .. ".json"
end

function M.delete_saved_workspace_file(constants, workspace_name)
	return os.remove(M.get_saved_workspace_file_path(constants, workspace_name))
end

function M.get_default_prog(constants)
	if constants.is_windows then
		return { "pwsh.exe", "-NoLogo" }
	end

	if constants.is_linux then
		return { os.getenv("SHELL") or "/bin/bash", "-l" }
	end

	if constants.is_darwin then
		return { os.getenv("SHELL") or "/bin/zsh", "-l" }
	end

	return { "/bin/sh" }
end

return M
