local M = {}

local function normalize_path(path)
	return (tostring(path or ""):gsub("\\", "/"):gsub("/+$", ""))
end

local function workspace_name(name)
	local normalized = tostring(name or ""):lower():gsub("[^%w%-_]+", "-"):gsub("%-+", "-")
	return normalized:gsub("^%-", ""):gsub("%-$", "")
end

local function basename(path)
	return (normalize_path(path):match("([^/]+)$")) or ""
end

local function directory_exists(path)
	local ok, _, code = os.rename(path, path)
	return ok or code == 13
end

local function is_git_repo(path)
	return directory_exists(normalize_path(path) .. "/.git")
end

local function add_project(projects, seen_paths, seen_workspaces, project)
	local path_key = normalize_path(project.path):lower()
	local workspace_key = tostring(project.workspace or ""):lower()
	if path_key == "" or workspace_key == "" or seen_paths[path_key] or seen_workspaces[workspace_key] then
		return
	end

	seen_paths[path_key] = true
	seen_workspaces[workspace_key] = true
	table.insert(projects, project)
end

local function pinned_projects(constants)
	return {
		{ id = "wezterm", label = "WezTerm config", workspace = "wezterm", path = constants.CONFIG_DIR, pinned = true },
		{ id = "config", label = "Dot config", workspace = "config", path = constants.HOME .. "/.config", pinned = true },
		{ id = "nvim", label = "Neovim config", workspace = "nvim", path = constants.HOME .. "/AppData/Local/nvim", pinned = true },
		{ id = "uni", label = "UNI", workspace = "uni", path = constants.HOME .. "/UNI", pinned = true },
		{ id = "dev", label = "Downloads Development", workspace = "dev", path = constants.HOME .. "/Downloads/Development", pinned = true },
		{ id = "g", label = "G drive", workspace = "g-drive", path = "G:/", pinned = true },
	}
end

local function scan_roots(constants)
	return {
		constants.HOME .. "/Downloads/Development",
		constants.HOME .. "/UNI",
		constants.HOME .. "/.config",
		"G:/",
	}
end

local function discovered_projects(wezterm, constants)
	local projects = {}
	for _, root in ipairs(scan_roots(constants)) do
		local ok, entries = pcall(wezterm.read_dir, root)
		if ok and entries then
			for _, path in ipairs(entries) do
				local name = basename(path)
				local workspace = workspace_name(name)
				if workspace ~= "" and is_git_repo(path) then
					table.insert(projects, {
						id = "dir:" .. normalize_path(path),
						label = name,
						workspace = workspace,
						path = normalize_path(path),
					})
				end
			end
		end
	end

	table.sort(projects, function(a, b)
		return a.label:lower() < b.label:lower()
	end)

	return projects
end

function M.list(wezterm, constants)
	local projects = {}
	local seen_paths = {}
	local seen_workspaces = {}

	for _, project in ipairs(pinned_projects(constants)) do
		add_project(projects, seen_paths, seen_workspaces, project)
	end

	for _, project in ipairs(discovered_projects(wezterm, constants)) do
		add_project(projects, seen_paths, seen_workspaces, project)
	end

	return projects
end

return M
