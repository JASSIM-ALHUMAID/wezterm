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
		red     = "#45585B",
		cyan    = "#E78446",
		magenta = "#B1603C",
		yellow  = "#55696C",
		green   = "#495D60",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#66787A", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#E78446",
		leader    = "#B1603C",            -- leader pill background (filled, like active tab)
		leader_fg = "#c3c7c8", -- text on the leader pill
		cwd       = "#66787A",
		process   = "#55696C",
		clock     = "#E78446",
		battery   = "#495D60",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#102026", -- bar / inactive / new-tab background
		fg        = "#c3c7c8", -- text on the bar
		gray      = "#5f7074",            -- dimmed inactive text / hover bg
		active_bg = "#E78446",            -- selected tab background (accent)
		active_fg = "#c3c7c8", -- selected tab text
	},
}
