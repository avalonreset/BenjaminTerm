# BenjaminTerm Release Notes (Draft)

## BenjaminTerm Is Live

BenjaminTerm is a Windows-first, hacker-styled terminal distribution built on WezTerm with practical quality-of-life upgrades for coding sessions.

This release includes:

- Full BenjaminTerm branding refresh across docs and distro materials
- Windows toast click-to-focus workflow (click notification -> jump to the right terminal pane/window)
- Linux friend-ready bootstrap flow with `benjaminterm` launcher
- Curated hotkeys and defaults documented for quick onboarding
- New custom BEN icon theme (blood-red square mark) across runtime + installer
- Windows co-install safety:
  - Separate AppUserModelID + executable names so BenjaminTerm and WezTerm can run/pin side-by-side without taskbar/icon collisions

## Why This Release Matters

- Faster interaction loop while coding
- Less terminal friction (copy/paste, focus, visual tweaks)
- Better out-of-box setup on Windows
- Portable path for Linux users without losing your preferred workflow

## Core Features

- Smart `Ctrl+C`:
  - Selection present: copy + clear selection
  - No selection: pass through true interrupt
- Smart paste:
  - Windows: `Ctrl+V`
  - Linux/macOS: `Ctrl+Shift+V`
- Paste undo/redo:
  - Undo: `Ctrl+Z`
  - Redo: `Ctrl+Shift+Z` (best effort)
- Theme cycling: `Ctrl+Alt+T`
- Font cycling: `Ctrl+Alt+F`
- Borderless toggle: `Ctrl+Alt+B`
- Window drag assist in borderless mode: `Ctrl+Alt+D`
- Config reload: `Ctrl+Shift+R`

## New in This Version

- Notification click focus:
  - Focusable terminal toast alerts now carry pane-aware click arguments
  - Clicking the Windows toast focuses the originating pane/tab/window
- GitHub/project refresh:
  - Project renamed to BenjaminTerm
  - README rewritten with Windows-first positioning and hotkey table
  - Linux docs updated for the `benjaminterm` command
- Installer branding refresh:
  - Inno Setup script now uses BenjaminTerm app naming and output filename
  - Explorer context menu entries updated to "Open BenjaminTerm here"

## Install Notes

### Windows (Primary)

- Use BenjaminTerm Windows release artifacts
- Default distro behavior includes vibe config and hacker-style defaults

### Linux (Friend Mode)

```sh
cd extras/vibe/linux
./bootstrap-popos.sh
benjaminterm
```

## Known Notes

- Some smart clipboard behavior is intentionally Windows-optimized.
- Linux paste-undo remains best effort depending on clipboard tooling (`wl-clipboard`, `xclip`, `xsel`).

## Attribution

BenjaminTerm is built on top of WezTerm (MIT license).
