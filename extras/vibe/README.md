# BenjaminTerm Vibe Layer

```text
██████  ███████ ███    ██      ██  █████  ███    ███ ██ ███    ██ ████████ ███████ ██████  ███    ███
██   ██ ██      ████   ██      ██ ██   ██ ████  ████ ██ ████   ██    ██    ██      ██   ██ ████  ████
██████  █████   ██ ██  ██      ██ ███████ ██ ████ ██ ██ ██ ██  ██    ██    █████   ██████  ██ ████ ██
██   ██ ██      ██  ██ ██ ██   ██ ██   ██ ██  ██  ██ ██ ██  ██ ██    ██    ██      ██   ██ ██  ██  ██
██████  ███████ ██   ████  █████  ██   ██ ██      ██ ██ ██   ████    ██    ███████ ██   ██ ██      ██
```

This folder contains the BenjaminTerm quality-of-life config layer:

- Config file: `extras/vibe/wezterm.lua`
- Goal: fast, low-friction, hacker-style terminal workflow
- Priority: Windows first, Linux/macOS supported

## Feature Set

- Smart copy behavior on `Ctrl+C`
- Smart paste behavior by platform
- Paste undo/redo
- Theme and font cycling
- Pure-black visual tuning
- Borderless mode + drag assist
- Persistent font/theme/window decoration state
- Windows toast-click focus workflow for focusable notifications
- Windows defaults to `WebGpu` renderer for smoother live reshape behavior
  - override with `BENJAMINTERM_FRONT_END=OpenGL|WebGpu|Software`

## Hotkeys

| Action | Hotkey |
|---|---|
| Smart copy / pass-through interrupt | `Ctrl+C` |
| Force pass-through interrupt | `Ctrl+Alt+C` or `Ctrl+Alt+Shift+C` |
| Smart paste (Windows) | `Ctrl+V` |
| Plain paste (Windows) | `Ctrl+Shift+V` |
| Smart paste (Linux/macOS) | `Ctrl+Shift+V` |
| Plain paste (Linux/macOS) | `Alt+V` |
| Paste undo | `Ctrl+Z` |
| Paste redo | `Ctrl+Shift+Z` |
| Reload config | `Ctrl+Shift+R` |
| Search | `Ctrl+F` |
| Font size down/up/reset | `Ctrl+-` / `Ctrl+=` / `Ctrl+0` |
| Cycle theme | `Ctrl+Alt+T` or `Ctrl+Alt+Shift+T` |
| Cycle font | `Ctrl+Alt+F` or `Ctrl+Alt+Shift+F` |
| Toggle borderless | `Ctrl+Alt+B` or `Ctrl+Alt+Shift+B` |
| Start window drag | `Ctrl+Alt+D` or `Ctrl+Alt+Shift+D` |

Letter hotkeys accept both Shift and non-Shift variants, so Caps Lock won't break them.

## Install Paths

### BenjaminTerm Windows Distro (Primary)

- The Windows distro bundles this config as `wezterm.lua` next to the executable.
- Fresh defaults:
  - Color scheme: `Blue Matrix` + forced black background.
  - Font: `OCR A Extended` with fallback chain.
- Per-user overrides:
  - `%USERPROFILE%\.wezterm.lua`
  - `~/.config/wezterm/wezterm.lua`

### Linux Quick Start

Use the bootstrap flow in `extras/vibe/linux/README.md`.
It installs an AppImage-based launcher command named:

- `benjaminterm`

Backward compatibility alias is also installed when possible:

- `wezterm-vibe`

## Notes

- Clipboard image detection uses Windows PowerShell APIs, so image-forwarding
  smart paste is Windows-only by design.
- Linux/macOS paste-undo is best effort and depends on clipboard tooling
  (`wl-paste`, `xclip`, `xsel`, `pbpaste`).
- This layer intentionally avoids deep source changes wherever possible.

## License

WezTerm is MIT licensed; see `LICENSE.md` at the repository root.
