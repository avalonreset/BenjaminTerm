# WezTerm Vibe QoL on Pop!_OS (Linux)

Pop!_OS is an Ubuntu-based Linux distribution from System76.

This repo ships a "Vibe QoL" config (`extras/vibe/wezterm.lua`) that works on
Linux/macOS/Windows. The easiest, most reliable way to test it on Pop!_OS is to
use the upstream WezTerm AppImage with a wrapper that pins the config file.

## Quick Start (Recommended)

1. Clone this repo.
2. Run the bootstrap script:

```sh
cd extras/vibe/linux
./bootstrap-popos.sh
```

It will:

- Download the latest stable upstream WezTerm `.AppImage`
- Install a small portable folder at `~/.local/opt/wezterm-vibe`
- Write `wezterm.lua` (the Vibe QoL config) into that folder
- Extract the AppImage (avoids FUSE dependency at runtime)
- Create `~/.local/bin/wezterm-vibe` (a wrapper command) if possible

Then launch with:

```sh
wezterm-vibe
```

## Notes / Troubleshooting

- Paste-undo on Linux is best-effort and depends on a clipboard helper:
  - Wayland: `wl-clipboard` (`wl-paste`)
  - X11: `xclip` or `xsel`

Install one:

```sh
sudo apt-get update
sudo apt-get install -y wl-clipboard xclip xsel
```

- Font: the default distro font is `OCR A Extended` (matches Windows vibe), but it
  may not be installed on Linux. The config will fall back to common monospace
  fonts (`DejaVu Sans Mono`, `monospace`, etc.), so it will still work.
