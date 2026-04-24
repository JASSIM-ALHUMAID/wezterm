local M = {}

-- Quick directory and app shortcuts.
function M.append(keys, constants, helpers)
	table.insert(keys, { key = "u", mods = "LEADER", action = helpers.quick_cd(constants.HOME .. "/UNI/") })
	table.insert(keys, { key = "i", mods = "LEADER", action = helpers.quick_cd(constants.HOME .. "/.config") })
	table.insert(keys, { key = "o", mods = "LEADER", action = helpers.quick_cd(constants.HOME .. "/AppData/Local/nvim") })
	table.insert(keys, { key = "v", mods = "LEADER", action = helpers.send_line("nvim .") })
	table.insert(keys, { key = "e", mods = "LEADER", action = helpers.send_line("yazi") })
	table.insert(keys, { key = "f", mods = "LEADER", action = helpers.quick_cd("G:/") })
	table.insert(keys, {
		key = "b",
		mods = "LEADER",
		action = helpers.send_line(constants.HOME .. "/Downloads/Development/btop4win/btop4win.exe"),
	})
end

return M
