# Releasing BenjaminTerm

This checklist is for preparing and publishing a BenjaminTerm GitHub release.

## 1. Validate Locally

Run at minimum:

```powershell
cargo check -p wezterm-toast-notification
cargo check -p wezterm-gui --quiet
```

## 2. Confirm Key Behaviors

- Windows toast click focuses originating terminal window/pane.
- Theme cycle works: `Ctrl+Alt+Shift+T`.
- Font cycle works: `Ctrl+Alt+Shift+F`.
- Borderless toggle works: `Ctrl+Alt+Shift+B`.
- Linux bootstrap script installs `benjaminterm` command.

## 3. Build Artifacts

### Windows (Primary)

- Build release binaries:

```powershell
cargo build --release -p wezterm-gui -p wezterm
```

- Optional installer packaging (if Inno Setup is installed):

```powershell
iscc ci/windows-installer.iss
```

### Compliance Pack Check (Windows Artifacts)

Confirm installer/zip artifacts include:

- `LICENSE.txt`
- `licenses/README.md`
- `licenses/THIRD_PARTY_NOTICES.md`
- `licenses/ANGLE.md`
- `licenses/LICENSE_OFL.txt`
- `licenses/LICENSE_POWERLINE_EXTRA.txt`
- `licenses/MICROSOFT_CONHOST_NOTICE.md`
- `licenses/MESA_NOTICE.md`

### Linux (Friend Distribution)

- Keep `extras/vibe/linux/bootstrap-popos.sh` and `extras/vibe/linux/README.md` current.
- Linux users bootstrap via AppImage download flow; no separate distro build is required for this fork workflow.

## 4. Release Notes Template

Include:

- Windows-first BenjaminTerm branding refresh.
- Vibe QoL hotkeys and defaults.
- New toast click-to-focus workflow.
- Linux bootstrap command: `benjaminterm`.

## 5. Publish

1. Push branch to GitHub.
2. Open PR and merge.
3. Tag release version.
4. Create GitHub release and attach Windows artifacts.
5. Include Linux bootstrap instructions in release notes.
