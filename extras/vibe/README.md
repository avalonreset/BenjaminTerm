# WesTerm (Vibe QoL)

```text
 __      __           _______
 \ \    / /__ ____   |_   __ \  ___ _ __ _ __ ___
  \ \/\/ / _ `(_-<     | |__) |/ _ \ '__| '_ ` _ \
   \_/\_/\__,_/__/     |  _  /|  __/ |  | | | | | |
                      _| | \ \ \___|_|  |_| |_| |_|
                     |____|  \_\
```

This folder is a small set of Windows-focused quality-of-life tweaks for
[WezTerm](../../README.md), implemented entirely via WezTerm's Lua configuration API.

No upstream source code changes are required for these behaviors.

## What This Adds

- Minimal UI:
  - Tab bar disabled (`enable_tab_bar = false`)
  - Default shell is PowerShell 7 (`pwsh.exe`) for proper per-user history
- Smart paste on `Ctrl+V`:
  - If the Windows clipboard contains an image: forward `Ctrl+V` into the running
    program (for image-aware TUIs, eg: Codex).
  - Otherwise: paste text normally from the clipboard.
- Paste undo:
  - After you paste, press `Ctrl+Z` (within ~30 seconds) to quickly wipe the paste
    without holding Backspace.
  - Redo is best-effort via `Ctrl+Shift+Z` when possible.

## Install

Copy `extras/vibe/wezterm.lua` to your home config path:

- Windows: `%USERPROFILE%\.wezterm.lua`

Then reload WezTerm (`Ctrl+Shift+R`) or restart it.

## Notes

- These behaviors are Windows-specific because the clipboard detection uses
  `powershell.exe Get-Clipboard`.
- The paste undo is a pragmatic "clear the paste quickly" feature, not a full
  editor-grade undo stack.

## License / Attribution

WezTerm is MIT licensed; see `LICENSE.md` at the repository root. This config is
derived from WezTerm's public configuration interfaces and is intended to be used
with WezTerm.

