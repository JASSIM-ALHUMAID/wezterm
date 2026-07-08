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
		red     = "#5E535B",
		cyan    = "#777285",
		magenta = "#D29674",
		yellow  = "#9A6C60",
		green   = "#A56046",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#B7866C", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#777285",
		leader    = "#D29674",            -- leader pill background (filled, like active tab)
		leader_fg = "#c2c5c7", -- text on the leader pill
		cwd       = "#B7866C",
		process   = "#9A6C60",
		clock     = "#777285",
		battery   = "#A56046",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#0e1721", -- bar / inactive / new-tab background
		fg        = "#c2c5c7", -- text on the bar
		gray      = "#5d6772",            -- dimmed inactive text / hover bg
		active_bg = "#777285",            -- selected tab background (accent)
		active_fg = "#c2c5c7", -- selected tab text
	},
}
