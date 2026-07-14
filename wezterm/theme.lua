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
		red     = "#F2602D",
		cyan    = "#5F6691",
		magenta = "#3B5889",
		yellow  = "#BC4B58",
		green   = "#A12A46",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#FD9434", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#5F6691",
		leader    = "#3B5889",            -- leader pill background (filled, like active tab)
		leader_fg = "#c1c1c3", -- text on the leader pill
		cwd       = "#FD9434",
		process   = "#BC4B58",
		clock     = "#5F6691",
		battery   = "#A12A46",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#080711", -- bar / inactive / new-tab background
		fg        = "#c1c1c3", -- text on the bar
		gray      = "#59566a",            -- dimmed inactive text / hover bg
		active_bg = "#5F6691",            -- selected tab background (accent)
		active_fg = "#c1c1c3", -- selected tab text

		-- Custom tab bar colors (tab-title.lua)
		default_bg  = "#080711", -- inactive tab body (near-black, blends with bar)
		default_fg  = "#c1c1c3", -- inactive tab text
		hover_bg    = "#3B5889", -- hovered tab body (magenta/blue)
		hover_fg    = "#c1c1c3", -- hovered tab text
		active_bg2  = "#FD9434", -- active tab body (orange, pops)
		active_fg2  = "#080711", -- active tab text
		unseen      = "#F2602D", -- unseen output badge (red)
		progress_ok = "#A12A46", -- progress success (green)
		progress_err = "#F2602D", -- progress error (red)
		progress_ind = "#c1c1c3", -- progress indeterminate (light)
	},
}
