local wezterm = require 'wezterm'
local act = wezterm.action

local paste_undo_window_seconds = 30
local paste_undo_max_chars = 200000
local paste_undo_fallback_chars = 50000

-- Theme/font: "hacker-ish", pure black background.
-- Use a curated set of built-in schemes and provide a hotkey to cycle them.

-- Persist the last selected theme/font so it survives restart/crash.
local state_path = wezterm.config_dir .. '/.wezterm-vibe-state.json'

local function read_file(path)
  local f = io.open(path, 'rb')
  if not f then
    return nil
  end
  local s = f:read '*a'
  f:close()
  return s
end

local function write_file_atomic(path, data)
  local tmp = path .. '.tmp'
  local f = io.open(tmp, 'wb')
  if not f then
    return false
  end
  f:write(data)
  f:close()

  -- On Windows, rename over an existing file can fail, so remove first.
  pcall(os.remove, path)
  local ok = os.rename(tmp, path)
  if not ok then
    pcall(os.remove, tmp)
    return false
  end
  return true
end

local function load_state()
  local s = read_file(state_path)
  if not s or s == '' then
    return {}
  end
  local ok, decoded = pcall(wezterm.json_parse, s)
  if ok and type(decoded) == 'table' then
    return decoded
  end
  return {}
end

local function save_state(st)
  local ok, json = pcall(wezterm.json_encode, st)
  if not ok or type(json) ~= 'string' then
    return
  end
  pcall(write_file_atomic, state_path, json)
end

local builtin_schemes = wezterm.color.get_builtin_schemes()
-- Distro defaults (what a brand new install will start with).
-- If the scheme/font aren't available on the target machine, the config will
-- fall back gracefully.
local DEFAULT_COLOR_SCHEME = 'Blue Matrix'
local DEFAULT_FONT_PRIMARY = 'OCR A Extended'

local hacker_scheme_candidates = {
  -- Strong "hacker terminal" vibes
  'hardhacker',
  'Matrix (terminal.sexy)',
  'Blue Matrix',
  'Cyberdyne',
  'Cobalt Neon',

  -- Popular dark dev themes
  'Dracula (Official)',
  'Gruvbox Dark (Gogh)',
  'Nord (Gogh)',
  'Night Owl (Gogh)',
}

local hacker_schemes = {}
for _, name in ipairs(hacker_scheme_candidates) do
  if builtin_schemes[name] then
    table.insert(hacker_schemes, name)
  end
end
if #hacker_schemes == 0 then
  hacker_schemes = { 'Builtin Dark' }
end

local persisted = load_state()

local function pick_default_scheme()
  local name = persisted and persisted.color_scheme
  if type(name) == 'string' and builtin_schemes[name] then
    return name
  end
  if builtin_schemes[DEFAULT_COLOR_SCHEME] then
    return DEFAULT_COLOR_SCHEME
  end
  return hacker_schemes[1]
end

-- Font cycling: curated "snob/hacker" fonts.
--
-- Notes:
-- - The first entries are fonts detected on this machine via `wezterm ls-fonts --list-system`.
-- - The "aspirational" fonts at the bottom require installation; until installed, they'll fall back.
local hacker_font_candidates = {
  -- Installed (Windows)
  { family = 'JetBrains Mono', weight = 'Medium' },
  'Cascadia Mono',
  'Cascadia Code',
  'IBM Plex Mono',
  'Source Code Pro',
  'Roboto Mono',
  'Ubuntu Mono',
  'Consolas',
  'PT Mono',
  'Lucida Sans Typewriter',
  'OCR A Extended',
  'VT323',

  -- If you want to expand this list, add only fonts that are freely redistributable,
  -- or keep them out-of-tree to avoid bundling/license friction.
}

local function make_hacker_font(primary)
  return wezterm.font_with_fallback {
    primary,
    -- Ensure we always have a sane mono fallback even if the "vibe" font isn't installed.
    { family = 'Cascadia Mono' },
    { family = 'Cascadia Code' },
    { family = 'JetBrains Mono', weight = 'Medium' },
    'Consolas',
    'Symbols Nerd Font Mono',
    'Noto Color Emoji',
  }
end

local function same_primary_font(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) == 'string' then
    return a == b
  end
  if type(a) == 'table' then
    return a.family == b.family and a.weight == b.weight and a.style == b.style and a.stretch == b.stretch
  end
  return false
end

local function pick_default_font_primary()
  local want = persisted and persisted.font_primary
  if want then
    for _, cand in ipairs(hacker_font_candidates) do
      if same_primary_font(cand, want) then
        return cand
      end
    end
  end

  -- Distro default: try to use the selected "vibe" font if it's in the rotation.
  for _, cand in ipairs(hacker_font_candidates) do
    if same_primary_font(cand, DEFAULT_FONT_PRIMARY) then
      return cand
    end
  end

  return hacker_font_candidates[1]
end

local function idx_for_primary(primary)
  for i, cand in ipairs(hacker_font_candidates) do
    if same_primary_font(cand, primary) then
      return i
    end
  end
  return 1
end

-- Align font cycling with the actual starting font, so Ctrl+Alt+F moves to the
-- next font in the list rather than an arbitrary entry.
local default_font_primary = pick_default_font_primary()
local default_font_idx = idx_for_primary(default_font_primary)

local font_idx_by_window_id = {}
local function get_font_idx(window)
  local id = window:window_id()
  local idx = font_idx_by_window_id[id]
  if not idx then
    idx = default_font_idx
    font_idx_by_window_id[id] = idx
  end
  return idx
end

-- Smart paste for Windows:
-- If the clipboard currently holds an image, forward Ctrl+V into the running program
-- (so apps like the Codex TUI can handle image paste). Otherwise, paste text normally.
local function clipboard_has_image()
  local ok, stdout, _ = wezterm.run_child_process {
    'powershell.exe',
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    -- `Get-Clipboard -Format Image` may return $null without throwing when there is
    -- no image. Emit an explicit sentinel so we can reliably detect it.
    "try { $img = Get-Clipboard -Format Image -ErrorAction Stop } catch { $img = $null }; if ($null -ne $img) { 'HAS_IMAGE' }",
  }
  return ok and stdout and stdout:find('HAS_IMAGE', 1, true) ~= nil
end

local function get_clipboard_text()
  local ok, stdout, _ = wezterm.run_child_process {
    'powershell.exe',
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    -- Use Console.Out.Write to avoid adding a trailing newline.
    "try { $t = Get-Clipboard -Raw -ErrorAction Stop } catch { $t = $null }; if ($null -ne $t) { [Console]::Out.Write($t) }",
  }
  if not ok then
    return nil
  end
  return stdout or ''
end

local function now_epoch_seconds()
  return tonumber(wezterm.time.now():format '%s') or 0
end

local paste_state_by_pane_id = {}

local function state_for_pane(pane)
  local id = pane:pane_id()
  local st = paste_state_by_pane_id[id]
  if not st then
    st = { undo = {}, redo = {}, last_paste_s = 0 }
    paste_state_by_pane_id[id] = st
  end
  return st
end

local function char_len(s)
  if utf8 and utf8.len then
    local n = utf8.len(s)
    if n then
      return n
    end
  end
  return #s
end

local function send_back_delete(pane, count)
  -- Use BS (0x08) for broadest compatibility. (DEL 0x7f is also common,
  -- but some Windows console applications expect BS).
  local chunk = 4096
  local bs = string.char(0x08)
  while count > 0 do
    local n = math.min(count, chunk)
    pane:send_text(string.rep(bs, n))
    count = count - n
  end
end

local smart_paste = wezterm.action_callback(function(window, pane)
  local before = pane:get_logical_lines_as_text(3) or ''

  -- Paste text first and *then* check for image.
  --
  -- This ordering matters for tools that do "paste via clipboard": they may
  -- temporarily replace clipboard contents, send Ctrl+V, and then restore the
  -- previous clipboard quickly. If we spend time checking for image *before*
  -- pasting, we can miss the temporary text and paste the restored clipboard.
  window:perform_action(act.PasteFrom 'Clipboard', pane)

  local after = pane:get_logical_lines_as_text(3) or ''
  local changed = before ~= after

  -- If the clipboard holds an image, forward Ctrl+V into the program so that
  -- image-aware TUIs (like Codex) can handle it.
  -- Only do this if the paste didn't visibly change the viewport; otherwise
  -- we'd risk forwarding Ctrl+V after successfully pasting text.
  if (not changed) and clipboard_has_image() then
    window:perform_action(act.SendKey { key = 'v', mods = 'CTRL' }, pane)
    return
  end

  local st = state_for_pane(pane)
  st.last_paste_s = now_epoch_seconds()

  -- Record a best-effort "undo last paste" entry for text pastes.
  -- This is not a full editor undo system; it tries to delete the pasted
  -- characters by sending DEL repeatedly.
  local text = get_clipboard_text()
  if text and text ~= '' then
    if char_len(text) > paste_undo_max_chars then
      return
    end
    table.insert(st.undo, {
      text = text,
      len = char_len(text),
    })
    st.redo = {}
  end
end)

local undo_paste = wezterm.action_callback(function(window, pane)
  local st = state_for_pane(pane)
  local age = now_epoch_seconds() - (st.last_paste_s or 0)
  local entry = st.undo[#st.undo]

  -- Only steal Ctrl+Z shortly after we performed a paste; otherwise, pass through.
  if age > paste_undo_window_seconds then
    window:perform_action(act.SendKey { key = 'z', mods = 'CTRL' }, pane)
    return
  end

  -- If we recorded the pasted text, delete that exact length.
  -- Otherwise, fall back to deleting a large number of characters to quickly
  -- clear the pasted input (best-effort).
  local n = entry and entry.len or paste_undo_fallback_chars
  send_back_delete(pane, n)

  if entry then
    table.remove(st.undo)
    table.insert(st.redo, entry)
  end
end)

local redo_paste = wezterm.action_callback(function(window, pane)
  local st = state_for_pane(pane)
  local entry = st.redo[#st.redo]
  if not entry then
    return
  end

  pane:send_paste(entry.text)
  table.remove(st.redo)
  table.insert(st.undo, entry)
  st.last_paste_s = now_epoch_seconds()
end)

local cycle_theme = wezterm.action_callback(function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.color_scheme or pick_default_scheme()
  local idx = 1
  for i, name in ipairs(hacker_schemes) do
    if name == current then
      idx = i
      break
    end
  end
  local next_name = hacker_schemes[(idx % #hacker_schemes) + 1]
  overrides.color_scheme = next_name
  overrides.colors = overrides.colors or {}
  overrides.colors.background = '#000000'
  window:set_config_overrides(overrides)

  persisted.color_scheme = overrides.color_scheme
  save_state(persisted)
end)

local cycle_font = wezterm.action_callback(function(window, pane)
  local id = window:window_id()
  local idx = get_font_idx(window)
  idx = (idx % #hacker_font_candidates) + 1
  font_idx_by_window_id[id] = idx

  local overrides = window:get_config_overrides() or {}
  local primary = hacker_font_candidates[idx]
  overrides.font = make_hacker_font(primary)
  window:set_config_overrides(overrides)

  persisted.font_primary = primary
  save_state(persisted)
end)

local function pick_default_window_decorations()
  local deco = persisted and persisted.window_decorations
  if type(deco) == 'string' and deco ~= '' then
    return deco
  end
  -- Default: keep the normal titlebar+resize border.
  return 'TITLE|RESIZE'
end

local config = {
  -- Use PowerShell 7 by default. Command history is a shell feature (PSReadLine),
  -- whereas cmd.exe history is not persisted across sessions by default.
  default_prog = { 'pwsh.exe', '-NoLogo' },

  enable_tab_bar = false,
  disable_default_key_bindings = true,

  -- Font: pick a crisp "hacker" mono with sensible fallbacks.
  font = make_hacker_font(default_font_primary),
  -- Disable ligatures for a more "terminal" look.
  harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },

  -- Theme: start with a curated built-in scheme and force pure black background.
  color_scheme = pick_default_scheme(),
  colors = {
    background = '#000000',
  },
  window_background_opacity = 1.0,
  win32_system_backdrop = 'Disable',

  -- On Windows the native titlebar color is controlled by the OS; if you want
  -- a "pure black" top edge, the reliable option is to remove the title bar.
  -- Toggle with Ctrl+Alt+B (see keys below).
  window_decorations = pick_default_window_decorations(),

  default_cursor_style = 'BlinkingBlock',

  keys = {
    -- Copy selection (Ctrl+Shift+C)
    { key = 'C', mods = 'CTRL', action = act.CopyTo 'Clipboard' },

    -- Paste: one key, two behaviors
    { key = 'v', mods = 'CTRL', action = smart_paste },

    -- Keep a guaranteed plain-text paste on Ctrl+Shift+V
    { key = 'V', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },

    -- Undo/redo the most recent paste (best-effort).
    -- Ctrl+Z is `key='z', mods='CTRL'` and Ctrl+Shift+Z is `key='Z', mods='CTRL'`.
    { key = 'z', mods = 'CTRL', action = undo_paste },
    { key = 'Z', mods = 'CTRL', action = redo_paste },
    -- More explicit variants to be resilient to `key_map_preference` and layout differences.
    { key = 'mapped:z', mods = 'CTRL', action = undo_paste },
    { key = 'mapped:Z', mods = 'CTRL', action = redo_paste },

    { key = 'R', mods = 'CTRL', action = act.ReloadConfiguration },

    { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
    { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
    { key = '0', mods = 'CTRL', action = act.ResetFontSize },

    { key = 'F', mods = 'CTRL', action = act.Search { CaseSensitiveString = '' } },

    -- Theme cycling (no OS notifications).
    { key = 'T', mods = 'CTRL|ALT', action = cycle_theme },

    -- Font cycling (no OS notifications).
    { key = 'F', mods = 'CTRL|ALT', action = cycle_font },

    -- Borderless toggle (removes the title bar; keeps resizable border).
    {
      key = 'B',
      mods = 'CTRL|ALT',
      action = wezterm.action_callback(function(window, pane)
        local overrides = window:get_config_overrides() or {}
        local current = overrides.window_decorations or pick_default_window_decorations()

        if current == 'RESIZE' then
          overrides.window_decorations = 'TITLE|RESIZE'
        else
          overrides.window_decorations = 'RESIZE'
        end

        window:set_config_overrides(overrides)

        persisted.window_decorations = overrides.window_decorations
        save_state(persisted)
      end),
    },

    -- Easier window move when borderless (titlebar hidden).
    { key = 'd', mods = 'CTRL|ALT', action = act.StartWindowDrag },
  },
}

return config

