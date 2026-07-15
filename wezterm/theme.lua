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
		red     = "#666177",
		cyan    = "#A46DA3",
		magenta = "#337AC5",
		yellow  = "#216E91",
		green   = "#84567C",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#636389", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#A46DA3",
		leader    = "#337AC5",            -- leader pill background (filled, like active tab)
		leader_fg = "#c5c6c8", -- text on the leader pill
		cwd       = "#636389",
		process   = "#216E91",
		clock     = "#A46DA3",
		battery   = "#84567C",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#191b23", -- bar / inactive / new-tab background
		fg        = "#c5c6c8", -- text on the bar
		gray      = "#616477",            -- dimmed inactive text / hover bg
		active_bg = "#A46DA3",            -- selected tab background (accent)
		active_fg = "#c5c6c8", -- selected tab text

		-- Custom tab bar colors (tab-title.lua)
		default_bg  = "#191b23", -- inactive tab body (near-black, blends with bar)
		default_fg  = "#c5c6c8", -- inactive tab text
		hover_bg    = "#337AC5",            -- hovered tab body (magenta/blue)
		hover_fg    = "#c5c6c8", -- hovered tab text
		active_bg2  = "#636389",  -- active tab body (orange, pops)
		active_fg2  = "#191b23", -- active tab text
		unseen      = "#666177",            -- unseen output badge (red)
		progress_ok = "#84567C",            -- progress success (green)
		progress_err = "#666177",           -- progress error (red)
		progress_ind = "#c5c6c8", -- progress indeterminate (light)
	},
}
