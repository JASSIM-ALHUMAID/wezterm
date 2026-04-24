local target = require("wezterm").target_triple

-- Environment and shared constants.
local HOME = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
local APPDATA = os.getenv("APPDATA") or (HOME .. "\\AppData\\Roaming")
local CONFIG_DIR = HOME .. "\\.config\\wezterm"
local STATE_DIR = CONFIG_DIR .. "\\state\\"

return {
	DEFAULT_WORKSPACE = "main",
	HOME = HOME,
	APPDATA = APPDATA,
	CONFIG_DIR = CONFIG_DIR,
	STATE_DIR = STATE_DIR,
	is_windows = target:find("windows") ~= nil,
	is_linux = target:find("linux") ~= nil,
	is_darwin = target:find("darwin") ~= nil,
	custom_colors = {
		red = "#D06F79",
		cyan = "#88C0D0",
		magenta = "#B48EAD",
		yellow = "#EBCB8B",
	},
}
