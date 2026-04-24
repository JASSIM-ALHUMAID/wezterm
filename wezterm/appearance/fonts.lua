local M = {}

-- Font stack and related typography.
function M.apply(config, wezterm)
	config.font = wezterm.font_with_fallback({
		{
			family = "Maple Mono NF",
			weight = "DemiBold",
			scale = 1.1,
		},
		{ family = "Symbols Nerd Font Mono", scale = 1.0 },
		{ family = "Noto Color Emoji" },
	})

	config.window_frame = {
		font = wezterm.font({ family = "Maple Mono NF", weight = "Bold" }),
		font_size = 11.0,
		active_titlebar_bg = "#1e1e1e",
		inactive_titlebar_bg = "#1e1e1e",
	}
end

return M
