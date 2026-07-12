# Associated Workspace (command launcher only)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Spawn workspace (inherit cwd)" entry to the `LEADER m` command launcher that creates a new workspace inheriting the current workspace's working directory.

**Architecture:** Add a `spawn_associated_workspace` function to `workspaces/prompts.lua` that reads the active pane's cwd, prompts for a name, and spawns a new workspace at that path. Register it in `keymaps/commands.lua` only — no dedicated keybind.

**Tech Stack:** Lua, WezTerm mux API

---

## Task 1: Add `spawn_associated_workspace` to prompts.lua

**Files:**
- Modify: `C:\Users\jassi\.config\wezterm\wezterm\workspaces\prompts.lua`

- [ ] **Step 1: Add the function inside `Module.attach`, after `rename_workspace`**

Insert after `rename_workspace()` (around line 128), before `toast_saved`:

```lua
function M.spawn_associated_workspace(window, pane)
    local current_workspace = window:active_workspace()
    local cwd_uri = pane:get_current_working_dir()
    local cwd = cwd_uri and cwd_uri.file_path or nil

    window:perform_action(
        act.PromptInputLine({
            description = "New workspace name (inherits cwd from " .. current_workspace .. "):",
            action = wezterm.action_callback(function(inner_window, inner_pane, line)
                if not line or line == "" then
                    return
                end

                M.touch_workspace_order(line)

                if cwd and cwd ~= "" then
                    local args = helpers.spawn_args(nil, cwd, nil)
                    inner_window:perform_action(
                        act.SpawnCommandInNewTab({
                            args = args,
                            workspace = line,
                        }),
                        inner_pane
                    )
                else
                    inner_window:perform_action(
                        act.SwitchToWorkspace({ name = line }),
                        inner_pane
                    )
                end
            end),
        }),
        pane
    )
end
```

- [ ] **Step 2: Verify the function is inside the `Module.attach` scope**

The function must be placed between `rename_workspace()` (line 110) and `toast_saved` (line 130), inside the `function Module.attach(M, ctx)` block. It uses `act`, `helpers`, and `M` from the closure context — all already available.

---

## Task 2: Add to command launcher

**Files:**
- Modify: `C:\Users\jassi\.config\wezterm\wezterm\keymaps\commands.lua`

- [ ] **Step 1: Add a command entry**

Insert into the `commands` table (after the `delete-workspace` entry around line 33):

```lua
{
    id = "spawn-associated-workspace",
    label = "Spawn workspace (inherit cwd)",
    run = function(window, pane)
        workspaces.spawn_associated_workspace(window, pane)
    end,
},
```

---

## Verification

- [ ] **Step 1: Open WezTerm and press `LEADER m`**
  - Expected: "Spawn workspace (inherit cwd)" appears in the launcher

- [ ] **Step 2: Select "Spawn workspace (inherit cwd)"**
  - Expected: prompt appears showing "New workspace name (inherits cwd from main):"
  - Expected: typing a name and pressing Enter creates a new workspace at the same directory

- [ ] **Step 3: Verify the new workspace appears in `LEADER s` menu**
  - Expected: new workspace name shows as `[loaded]`

- [ ] **Step 4: Verify cwd is inherited**
  - Expected: the new workspace's pane starts in the same directory as the source workspace
