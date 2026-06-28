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
		red     = "#4F626A",
		cyan    = "#6D8C93",
		magenta = "#837E81",
		yellow  = "#EB9B77",
		green   = "#AD5E4A",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#597984", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#6D8C93",
		leader    = "#837E81",            -- leader pill background (filled, like active tab)
		leader_fg = "#c3c3c3", -- text on the leader pill
		cwd       = "#597984",
		process   = "#EB9B77",
		clock     = "#6D8C93",
		battery   = "#AD5E4A",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#121112", -- bar / inactive / new-tab background
		fg        = "#c3c3c3", -- text on the bar
		gray      = "#6e5959",            -- dimmed inactive text / hover bg
		active_bg = "#6D8C93",            -- selected tab background (accent)
		active_fg = "#c3c3c3", -- selected tab text
	},
}
