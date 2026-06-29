local act = require("wezterm").action
local helpers = require("wezterm.helpers")

local M = {}

-- Pane movement and resizing bindings.
function M.append(keys, wezterm, constants)
	local function spawn_in_cwd(window, pane, direction)
		local cwd_uri = pane:get_current_working_dir()
		local cwd = cwd_uri and cwd_uri.file_path or nil
		local shell = helpers.detect_shell(pane:get_foreground_process_name())
		local args = helpers.win_spawn_args(shell, cwd, helpers.get_default_prog(constants))
		window:spawn({
			args = args,
			domain = {
				DomainName = "local",
				SplitPane = { direction = direction, size = { Percent = 50 } },
			},
		})
	end

	table.insert(keys, {
		key = "]",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			spawn_in_cwd(window, pane, "Bottom")
		end),
	})
	table.insert(keys, {
		key = "[",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			spawn_in_cwd(window, pane, "Right")
		end),
	})
	table.insert(keys, { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") })
	table.insert(keys, { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") })
	table.insert(keys, { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") })
	table.insert(keys, { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") })
	table.insert(keys, { key = "phys:Space", mods = "LEADER", action = act.RotatePanes("Clockwise") })
	table.insert(keys, { key = "z", mods = "LEADER", action = act.TogglePaneZoomState })
	table.insert(keys, {
		key = "x",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			wezterm.time.call_after(0.05, function()
				window:perform_action(act.CloseCurrentPane({ confirm = false }), pane)
			end)
		end),
	})
	table.insert(keys, { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) })
end

return M
