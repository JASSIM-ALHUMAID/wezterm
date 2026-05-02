local M = {}

-- Fuzzy cheat sheet for leader-driven workflows.
function M.append(keys, wezterm)
	local act = wezterm.action
	local choices = {
		{ label = "Commands    LEADER m      Command launcher" },
		{ label = "Projects    LEADER P      Project workspace launcher" },
		{ label = "Workspaces  LEADER s      Workspace menu" },
		{ label = "Workspaces  LEADER S      Save current workspace" },
		{ label = "Workspaces  LEADER L      Switch/load workspace" },
		{ label = "Workspaces  LEADER R      Rename workspace" },
		{ label = "Workspaces  LEADER D      Delete workspace" },
		{ label = "Tabs        LEADER c      New tab" },
		{ label = "Tabs        LEADER n/p    Next/previous tab" },
		{ label = "Tabs        LEADER 1-9    Activate tab" },
		{ label = "Tabs        LEADER ,      Rename tab" },
		{ label = "Tabs        LEADER .      Move tab mode" },
		{ label = "Panes       LEADER [/]    Split pane" },
		{ label = "Panes       LEADER h/j/k/l Move between panes" },
		{ label = "Panes       LEADER r      Resize pane mode" },
		{ label = "Panes       LEADER z      Zoom pane" },
		{ label = "Panes       LEADER x      Close pane" },
		{ label = "Quick dirs  LEADER i/o/u/f cd shortcuts" },
		{ label = "Apps        LEADER v/e/b  nvim/yazi/btop" },
		{ label = "General     LEADER ;      Command palette" },
		{ label = "General     LEADER Ctrl+r Reload config" },
		{ label = "General     LEADER y      Copy mode" },
		{ label = "Search      LEADER /      Search scrollback" },
		{ label = "Search      LEADER C      Clear scrollback" },
		{ label = "Search      LEADER PgUp/PgDn Scroll pages" },
		{ label = "General     LEADER F      Fullscreen" },
	}

	table.insert(keys, {
		key = "?",
		mods = "LEADER|SHIFT",
		action = act.InputSelector({
			title = "Leader help",
			description = "Search available leader shortcuts",
			fuzzy_description = "Shortcut: ",
			fuzzy = true,
			choices = choices,
			action = wezterm.action_callback(function() end),
		}),
	})
end

return M
