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
		red     = "#225DB1",
		cyan    = "#3D83CB",
		magenta = "#5486B8",
		yellow  = "#1F60C1",
		green   = "#4875AB",
	},

	-- Status-bar accents (events.lua). Hues stay fixed across light/dark
	-- because pywal already contrasts them with the wallpaper. To force a
	-- per-brightness color on an item, use the LD token, e.g. color1 for
	-- light and color9 for dark.
	status = {
		workspace = "#3276C5", -- "main" label: dark accent on light bars, bright on dark
		mode      = "#3D83CB",
		leader    = "#5486B8",            -- leader pill background (filled, like active tab)
		leader_fg = "#c1c3c5", -- text on the leader pill
		cwd       = "#3276C5",
		process   = "#1F60C1",
		clock     = "#3D83CB",
		battery   = "#4875AB",
	},

	-- Tab/status bar surface. Flips with wallpaper brightness so the bar
	-- stays readable: LIGHT wallpaper -> light bg + dark text, DARK -> reverse.
	tab_bar = {
		bg        = "#0a1017", -- bar / inactive / new-tab background
		fg        = "#c1c3c5", -- text on the bar
		gray      = "#59626d",            -- dimmed inactive text / hover bg
		active_bg = "#3D83CB",            -- selected tab background (accent)
		active_fg = "#c1c3c5", -- selected tab text

		-- Custom tab bar colors (tab-title.lua)
		default_bg  = "#0a1017", -- inactive tab body (near-black, blends with bar)
		default_fg  = "#c1c3c5", -- inactive tab text
		hover_bg    = "#5486B8",            -- hovered tab body (magenta/blue)
		hover_fg    = "#c1c3c5", -- hovered tab text
		active_bg2  = "#3276C5",  -- active tab body (orange, pops)
		active_fg2  = "#0a1017", -- active tab text
		unseen      = "#225DB1",            -- unseen output badge (red)
		progress_ok = "#4875AB",            -- progress success (green)
		progress_err = "#225DB1",           -- progress error (red)
		progress_ind = "#c1c3c5", -- progress indeterminate (light)
	},
}
