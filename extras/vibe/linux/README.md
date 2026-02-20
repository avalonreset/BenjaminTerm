# BenjaminTerm Linux Bootstrap (Pop!_OS / Ubuntu)

BenjaminTerm is Windows-first, but this bootstrap flow gives Linux users a clean,
portable launcher with the same vibe config.

## Quick Start

```sh
cd extras/vibe/linux
./bootstrap-popos.sh
```

The script will:

- Download the latest stable upstream WezTerm `.AppImage`
- Install a portable folder at `~/.local/opt/benjaminterm`
- Copy config to `benjaminterm.lua`
- Extract the AppImage (no runtime FUSE dependency)
- Create launcher command:
  - `~/.local/bin/benjaminterm`
- Try to create compatibility alias:
  - `~/.local/bin/wezterm-vibe`

Launch with:

```sh
benjaminterm
```

## Feature Expectations on Linux

- Smart paste uses `Ctrl+Shift+V` (Linux/macOS convention).
- Theme cycle: `Ctrl+Alt+T`.
- Font cycle: `Ctrl+Alt+F`.
- Borderless toggle: `Ctrl+Alt+B`.
- Paste undo is best effort and depends on clipboard helpers.

Install helpers:

```sh
sudo apt-get update
sudo apt-get install -y wl-clipboard xclip xsel
```

## Notes

- The config is shared across Windows/Linux/macOS, but some behavior is intentionally
  Windows-optimized (for example image-aware paste forwarding and native toast workflow).
- Font fallback is automatic if `OCR A Extended` is not installed.
