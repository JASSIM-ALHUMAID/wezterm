local M = {}

-- Tab bar color styling.
function M.apply(config, constants)
	config.colors = {
		tab_bar = {
			background = "#1e1e1e",
			active_tab = {
				bg_color = constants.custom_colors.cyan,
				fg_color = "#1e1e1e",
				intensity = "Bold",
				underline = "None",
			},
			inactive_tab = {
				bg_color = "#2a2a2a",
				fg_color = "#808080",
			},
			inactive_tab_hover = {
				bg_color = "#3b4252",
				fg_color = "#d8dee9",
			},
			new_tab = {
				bg_color = "#1e1e1e",
				fg_color = "#d8dee9",
			},
		},
	}
end

return M
