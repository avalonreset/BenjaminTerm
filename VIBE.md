# WezTerm Vibe QoL (Windows)

This fork branch is primarily a **configuration-based** set of quality-of-life
improvements built on top of upstream WezTerm, using its Lua configuration API.

A small Windows-only Rust tweak is included so the distro can ship a bundled
default config (`wezterm.lua` next to the executable) while still allowing the
per-user config paths to override it.

## What Changed

All of the "vibe" behavior lives in:

- `extras/vibe/wezterm.lua`
- `extras/vibe/README.md`

Highlights:

- Disable the tab bar (`enable_tab_bar = false`) for a cleaner single-terminal UI.
- Default shell set to PowerShell 7 (`pwsh.exe`) for proper persistent history.
- Better font zoom behavior:
  - Default font size is larger (`16.0` pt).
  - `Ctrl++`/`Ctrl+-` reflows text without resizing the whole window.
- Smart `Ctrl+V`:
  - Paste text normally when the clipboard holds text.
  - If the clipboard holds an image, forward `Ctrl+V` to the running program so
    image-aware TUIs can ingest the clipboard image.
- Paste undo:
  - After pasting, press `Ctrl+Z` (within a short window) to quickly wipe the
    paste without holding backspace.

## Install

Copy `extras/vibe/wezterm.lua` to:

- Windows: `%USERPROFILE%\.wezterm.lua`

Reload config (`Ctrl+Shift+R`) or restart WezTerm.

## License

WezTerm is MIT licensed; see `LICENSE.md`.
