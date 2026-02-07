local wezterm = require 'wezterm'
local act = wezterm.action

local paste_undo_window_seconds = 30
local paste_undo_max_chars = 200000
local paste_undo_fallback_chars = 50000

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
      window:toast_notification('wezterm', 'Paste too large to record for undo', nil, 4000)
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
  window:toast_notification('wezterm', 'Undo paste', nil, 1200)
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
    window:toast_notification('wezterm', 'Nothing to redo', nil, 2000)
    return
  end

  pane:send_paste(entry.text)
  table.remove(st.redo)
  table.insert(st.undo, entry)
  st.last_paste_s = now_epoch_seconds()
end)

return {
  -- Use PowerShell 7 by default. Command history is a shell feature (PSReadLine),
  -- whereas cmd.exe history is not persisted across sessions by default.
  default_prog = { 'pwsh.exe', '-NoLogo' },

  enable_tab_bar = false,
  disable_default_key_bindings = true,

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
  },
}

