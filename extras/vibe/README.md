# WezTerm (Vibe QoL)

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
- Theme cycling:
  - `Ctrl+Alt+T` cycles through a curated set of built-in "hacker-ish" themes and
    forces a pure black background.
- Font cycling:
  - `Ctrl+Alt+F` cycles through a curated set of hacker fonts (installed fonts first).
  - The list is intentionally limited to fonts already present on this Windows setup
    plus other freely-available fonts (no paid fonts in the rotation).
- Persistence:
  - The last selected theme/font are saved to a small state file so they survive
    restarts and crashes: `%USERPROFILE%\\.wezterm-vibe-state.json`.
  - Delete that file to reset back to defaults.
- Borderless titlebar:
  - `Ctrl+Alt+B` toggles the title bar off/on (`window_decorations = "RESIZE"` vs
    `window_decorations = "TITLE|RESIZE"`).
  - On Windows the titlebar color is managed by the OS; borderless is the reliable
    way to get a "pure black" top edge.
  - `Ctrl+Alt+D` triggers `StartWindowDrag` to move the window more easily when
    the titlebar is hidden.

## Install

### Using This Fork's Windows Distro

Nothing to do: the Windows installer and portable `.zip` bundle the Vibe QoL
config as `wezterm.lua` next to the executable, so a fresh install starts with:

- Color scheme: `Blue Matrix` (pure black background forced)
- Font: `OCR A Extended` (falls back to Cascadia/JetBrains/Consolas if missing)

To customize, create a per-user config file; it will override the bundled one:

- Windows: `%USERPROFILE%\.wezterm.lua`
- Or: `~/.config/wezterm/wezterm.lua`

### Using Upstream WezTerm

Copy `extras/vibe/wezterm.lua` to your home config path:

- Windows: `%USERPROFILE%\.wezterm.lua`

Then reload WezTerm (`Ctrl+Shift+R`) or restart it.

### Linux (Pop!_OS / Ubuntu) Quick Start

See `extras/vibe/linux/README.md` for a bootstrap script that downloads the
upstream WezTerm AppImage and runs it pinned to this config.

## Notes

- These behaviors are Windows-specific because the clipboard detection uses
  `powershell.exe Get-Clipboard`. On Linux/macOS, the config intentionally does
  not attempt to forward `Ctrl+V` into applications when an image is on the
  clipboard (because `Ctrl+V` can have meaning inside shells/TUIs). Paste-undo
  is best-effort and depends on a clipboard helper being available (`wl-paste`,
  `xclip`, `xsel`, `pbpaste`).
- The paste undo is a pragmatic "clear the paste quickly" feature, not a full
  editor-grade undo stack.

## License / Attribution

WezTerm is MIT licensed; see `LICENSE.md` at the repository root. This config is
derived from WezTerm's public configuration interfaces and is intended to be used
with WezTerm.
