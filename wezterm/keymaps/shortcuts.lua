local act = require("wezterm").action

local M = {}

-- Quick directory and app shortcuts.
function M.append(keys, constants, helpers)
	-- Shell launchers (Windows): fish is the default, G drops to PowerShell.
	if constants.is_windows then
		table.insert(keys, {
			key = "g",
			mods = "LEADER",
			action = act.SpawnCommandInNewTab({ args = helpers.win_fish_prog() }),
		})
		table.insert(keys, {
			key = "G",
			mods = "LEADER|SHIFT",
			action = act.SpawnCommandInNewTab({ args = helpers.win_pwsh_prog() }),
		})
	end
end

return M
