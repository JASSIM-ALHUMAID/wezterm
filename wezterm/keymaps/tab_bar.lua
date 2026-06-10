local M = {}

local window_states = {}

function M.append(keys, wezterm)
	table.insert(keys, {
		key = "t",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, _)
			local window_id = window:window_id()
			local shown = window_states[window_id]

			if shown then
				window_states[window_id] = false
				window:set_config_overrides({ enable_tab_bar = false })
			else
				window_states[window_id] = true
				window:set_config_overrides({ enable_tab_bar = true })
			end
		end),
	})
end

return M
