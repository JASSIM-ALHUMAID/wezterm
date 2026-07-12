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
		red     = "#B13306",
		cyan    = "#9C6657",
		magenta = "#AE4401",
		yellow  = "#C5331B",
		green   = "#BA2121",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#CE2C28", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#9C6657",
		leader    = "#AE4401",            -- leader pill background (filled, like active tab)
		leader_fg = "#c6c3c2", -- text on the leader pill
		cwd       = "#CE2C28",
		process   = "#C5331B",
		clock     = "#9C6657",
		battery   = "#BA2121",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#1d110c", -- bar / inactive / new-tab background
		fg        = "#c6c3c2", -- text on the bar
		gray      = "#70615c",            -- dimmed inactive text / hover bg
		active_bg = "#9C6657",            -- selected tab background (accent)
		active_fg = "#c6c3c2", -- selected tab text
	},
}
