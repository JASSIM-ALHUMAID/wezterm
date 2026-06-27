-- =====================================================================
--  theme.lua  --  SINGLE SOURCE of all themed WezTerm colors.
--
--  Generated from theme.lua.template by ~/.config/yasb/colorScheme.ps1 on
--  every wallpaper change. EDIT THE .template, never theme.lua directly.
--
--  Token syntax (write each wrapped in curly braces in the values below):
--    colorN              -> pywal hex (#rrggbb), N = 0..15
--    background/foreground/cursor -> pywal special hex
--    LD:lightCol,darkCol -> lightCol on LIGHT wallpapers, darkCol on DARK
--                           (no spaces inside the braces)
-- =====================================================================
return {
	-- Terminal/tab accent palette.
	custom_colors = {
		red     = "#27485B",
		cyan    = "#808F95",
		magenta = "#4F7089",
		yellow  = "#585965",
		green   = "#2C4E6D",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#96726A", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#808F95",
		leader    = "#4F7089",            -- leader pill background (filled, like active tab)
		leader_fg = "#c2c3c6", -- text on the leader pill
		cwd       = "#96726A",
		process   = "#585965",
		clock     = "#808F95",
		battery   = "#2C4E6D",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#0c101b", -- bar / inactive / new-tab background
		fg        = "#c2c3c6", -- text on the bar
		gray      = "#5b5f6f",            -- dimmed inactive text / hover bg
		active_bg = "#808F95",            -- selected tab background (accent)
		active_fg = "#c2c3c6", -- selected tab text
	},
}
