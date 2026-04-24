local M = {}
local cached_resurrect

-- Load and cache external plugins.
function M.setup(constants)
	if cached_resurrect then
		return cached_resurrect
	end

	package.path = table.concat({
		package.path,
		constants.APPDATA
			.. "\\wezterm\\plugins\\httpssCssZssZsgithubsDscomsZsMLFlexersZsresurrectsDswezterm\\plugin\\?.lua",
		constants.APPDATA
			.. "\\wezterm\\plugins\\httpssCssZssZsgithubsDscomsZsMLFlexersZsresurrectsDswezterm\\plugin\\?\\init.lua",
	}, ";")

	cached_resurrect = {
		workspace_state = require("resurrect.workspace_state"),
		window_state = require("resurrect.window_state"),
		state_manager = require("resurrect.state_manager"),
	}

	cached_resurrect.state_manager.save_state_dir = constants.STATE_DIR
	return cached_resurrect
end

return M
