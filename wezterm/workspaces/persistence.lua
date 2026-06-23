local Module = {}

-- Save and restore workspace sessions (tabs + panes + working dirs) to disk.
function Module.attach(M, ctx)
	local wezterm = ctx.wezterm
	local constants = ctx.constants

	local STATE_DIR = wezterm.config_dir .. "/state/workspaces"

	-- Map an arbitrary workspace name to a safe filename stem.
	local function sanitize(name)
		local s = tostring(name or ""):lower():gsub("[^%w%-_]+", "-"):gsub("%-+", "-")
		return (s:gsub("^%-", ""):gsub("%-$", ""))
	end

	local function state_path(name)
		local stem = sanitize(name)
		if stem == "" then
			return nil
		end
		return STATE_DIR .. "/" .. stem .. ".json"
	end

	-- Make a path WezTerm's spawn cwd accepts on both Windows and POSIX.
	-- get_current_working_dir() yields e.g. "/C:/Users/..." on Windows.
	local function normalize_cwd(path)
		path = tostring(path or ""):gsub("\\", "/")
		-- Strip a single leading slash that precedes a Windows drive letter.
		path = path:gsub("^/(%a:/)", "%1")
		return path
	end

	local function ensure_state_dir()
		-- mkdir -p, guarded; harmless if it already exists.
		pcall(os.execute, 'mkdir "' .. STATE_DIR:gsub("/", constants.is_windows and "\\" or "/") .. '"')
	end

	local function read_file(path)
		local f = io.open(path, "r")
		if not f then
			return nil
		end
		local data = f:read("*a")
		f:close()
		return data
	end

	local function write_file(path, data)
		local f = io.open(path, "w")
		if not f then
			ensure_state_dir()
			f = io.open(path, "w")
		end
		if not f then
			return false
		end
		f:write(data)
		f:close()
		return true
	end

	local function pane_cwd(pane)
		local ok, uri = pcall(function()
			return pane:get_current_working_dir()
		end)
		if not ok or not uri then
			return nil
		end
		-- Newer WezTerm returns a Url object; older returns a string.
		local raw = type(uri) == "string" and uri or uri.file_path
		if not raw or raw == "" then
			return nil
		end
		return normalize_cwd(raw)
	end

	-- TUI programs worth relaunching on restore. Anything else (notably the
	-- shell itself at a prompt) is treated as "no program".
	local ALLOWED_PROGRAMS = {
		nvim = true,
		vim = true,
		helix = true,
		hx = true,
		yazi = true,
		ranger = true,
		lf = true,
		nnn = true,
		btop = true,
		btop4win = true,
		htop = true,
		top = true,
		btm = true,
		bottom = true,
		lazygit = true,
		gitui = true,
		tig = true,
		lazydocker = true,
		k9s = true,
		ncdu = true,
	}

	-- The full executable path of an allowlisted foreground program, else nil.
	-- We store the absolute path (like cwd) so it relaunches reliably on this
	-- machine even when the program isn't on PATH.
	local function pane_program(pane)
		local ok, name = pcall(function()
			return pane:get_foreground_process_name()
		end)
		if not ok or type(name) ~= "string" or name == "" then
			return nil
		end
		local normalized = name:gsub("\\", "/")
		local base = (normalized:match("([^/]+)$") or normalized):gsub("%.exe$", ""):lower()
		if ALLOWED_PROGRAMS[base] then
			return normalized
		end
		return nil
	end

	-- Build spawn args that run an allowlisted program *inside* an interactive
	-- shell, so the pane drops back to a prompt when the program exits instead
	-- of the pane closing. Returns nil for a plain shell.
	local function spawn_args(prog)
		if not prog then
			return nil
		end
		if constants.is_windows then
			return { "pwsh.exe", "-NoLogo", "-NoExit", "-Command", "& '" .. prog .. "'" }
		end
		local shell = os.getenv("SHELL") or "/bin/bash"
		return { shell, "-c", "'" .. prog .. "' ; exec '" .. shell .. "'" }
	end

	-- Find the first mux window bound to the given workspace.
	local function mux_window_for(name)
		for _, mux_win in ipairs(wezterm.mux.all_windows()) do
			if mux_win:get_workspace() == name then
				return mux_win
			end
		end
		return nil
	end

	local function serialize_window(mux_win, name)
		local data = { name = name, tabs = {} }
		for _, tab in ipairs(mux_win:tabs()) do
			local tab_entry = { title = tab:get_title() or "", active = false, panes = {} }
			local ok, infos = pcall(function()
				return tab:panes_with_info()
			end)
			if ok and infos then
				for _, info in ipairs(infos) do
					table.insert(tab_entry.panes, {
						cwd = pane_cwd(info.pane),
						prog = pane_program(info.pane),
						active = info.is_active == true,
					})
					if info.is_active then
						tab_entry.active = true
					end
				end
			end
			if #tab_entry.panes > 0 then
				table.insert(data.tabs, tab_entry)
			end
		end
		return data
	end

	function M.save_workspace_by_name(name)
		-- The default workspace is ephemeral by design (spawned fresh at startup,
		-- never restored), so it must never be persisted.
		if not name or name == "" or name == constants.DEFAULT_WORKSPACE then
			return false
		end
		local path = state_path(name)
		if not path then
			return false
		end

		local ok, result = pcall(function()
			local mux_win = mux_window_for(name)
			if not mux_win then
				return false
			end
			local data = serialize_window(mux_win, name)
			if #data.tabs == 0 then
				return false
			end
			return write_file(path, wezterm.json_encode(data))
		end)

		return ok and result == true
	end

	local function spawn_pane_layout(tab, first_pane, panes)
		-- Active pane occupies the first slot; split out the rest with
		-- alternating directions for a simple, predictable layout.
		local active_pane = first_pane
		local last_pane = first_pane
		for i = 2, #panes do
			local entry = panes[i]
			local direction = (i % 2 == 0) and "Right" or "Down"
			local ok, new_pane = pcall(function()
				return last_pane:split({
					direction = direction,
					cwd = entry.cwd,
					args = spawn_args(entry.prog),
				})
			end)
			if ok and new_pane then
				last_pane = new_pane
				if entry.active then
					active_pane = new_pane
				end
			end
		end
		if active_pane and active_pane ~= first_pane then
			pcall(function()
				active_pane:activate()
			end)
		end
	end

	function M.restore_workspace_by_name(name)
		if not name or name == constants.DEFAULT_WORKSPACE then
			return false
		end
		local path = state_path(name)
		if not path then
			return false
		end

		local raw = read_file(path)
		if not raw or raw == "" then
			return false
		end

		local ok, data = pcall(wezterm.json_parse, raw)
		if not ok or type(data) ~= "table" or type(data.tabs) ~= "table" or #data.tabs == 0 then
			return false
		end

		local restored = pcall(function()
			local first = (data.tabs[1].panes or {})[1] or {}

			local spawn_tab, spawn_pane, mux_win = wezterm.mux.spawn_window({
				workspace = name,
				cwd = first.cwd,
				args = spawn_args(first.prog),
			})

			for index, tab_entry in ipairs(data.tabs) do
				local tab, pane
				if index == 1 then
					tab, pane = spawn_tab, spawn_pane
				else
					local lead = tab_entry.panes[1] or {}
					local t, p = mux_win:spawn_tab({
						cwd = lead.cwd,
						args = spawn_args(lead.prog),
					})
					tab, pane = t, p
				end

				if tab and tab_entry.title and tab_entry.title ~= "" then
					pcall(function()
						tab:set_title(tab_entry.title)
					end)
				end

				if pane and tab_entry.panes and #tab_entry.panes > 1 then
					spawn_pane_layout(tab, pane, tab_entry.panes)
				end
			end

			return true
		end)

		return restored == true
	end
end

return Module
