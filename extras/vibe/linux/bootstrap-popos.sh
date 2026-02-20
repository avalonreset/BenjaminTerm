#!/usr/bin/env sh
set -eu

say() {
  printf '%s\n' "$*"
}

have_path_entry() {
  # returns 0 if $1 is present in PATH as a full entry
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *) return 1 ;;
  esac
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

detect_os() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    say "Detected OS: ${PRETTY_NAME:-unknown}"
  fi
}

here_dir() {
  # POSIX-ish: resolve the directory containing this script
  # shellcheck disable=SC2169,SC2039
  cd -- "$(dirname -- "$0")" && pwd
}

REPO_ROOT="$(cd -- "$(here_dir)/../../.." && pwd)"
VIBE_SRC="$REPO_ROOT/extras/vibe/wezterm.lua"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/opt/benjaminterm}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

APPIMAGE="$INSTALL_DIR/BenjaminTerm.AppImage"
CFG="$INSTALL_DIR/benjaminterm.lua"
ROOT="$INSTALL_DIR/squashfs-root"
GUI_BIN="$ROOT/usr/bin/wezterm-gui"
CLI_BIN="$ROOT/usr/bin/wezterm"
WRAPPER="$INSTALL_DIR/benjaminterm"
BIN_LINK="$BIN_DIR/benjaminterm"
COMPAT_BIN_LINK="$BIN_DIR/wezterm-vibe"

mkdir -p "$INSTALL_DIR"

if [ ! -f "$VIBE_SRC" ]; then
  say "error: expected vibe config at: $VIBE_SRC"
  exit 1
fi

cp -f "$VIBE_SRC" "$CFG"

say "Installed vibe config: $CFG"

if ! need_cmd curl && ! need_cmd wget; then
  say "error: need either 'curl' or 'wget' to download the AppImage"
  say "Pop!_OS: sudo apt-get update && sudo apt-get install -y curl"
  exit 1
fi

tmp_json="$INSTALL_DIR/.wezterm-release.json"

say "Fetching latest stable WezTerm release metadata..."
if need_cmd curl; then
  curl -fsSL "https://api.github.com/repos/wez/wezterm/releases/latest" >"$tmp_json"
else
  wget -qO - "https://api.github.com/repos/wez/wezterm/releases/latest" >"$tmp_json"
fi

pick_url() {
  if need_cmd python3; then
    python3 - "$tmp_json" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
  data = json.load(f)
assets = data.get("assets") or []

def ok(a):
  name = (a.get("name") or "")
  if not name.endswith(".AppImage"):
    return False
  if name.endswith(".AppImage.zsync"):
    return False
  # Prefer Ubuntu AppImage builds when present.
  return "Ubuntu" in name

cands = [a for a in assets if ok(a)]
if not cands:
  cands = [a for a in assets if (a.get("name") or "").endswith(".AppImage") and not (a.get("name") or "").endswith(".AppImage.zsync")]

def score(a):
  name = (a.get("name") or "")
  s = 0
  if "Ubuntu20.04" in name:
    s += 3
  if "Ubuntu22.04" in name:
    s += 2
  if "Ubuntu" in name:
    s += 1
  return s

if not cands:
  sys.exit(2)

cands.sort(key=score, reverse=True)
print(cands[0].get("browser_download_url") or "")
PY
  fi

  # Fallback: very simple grep-based parse (works if GitHub JSON stays stable).
  # Prefer Ubuntu AppImage links.
  grep -Eo '"browser_download_url"\s*:\s*"[^"]+\.AppImage"' "$tmp_json" \
    | grep -E 'Ubuntu' \
    | head -n 1 \
    | sed -E 's/.*"([^"]+)".*/\1/'
}

URL="$(pick_url || true)"
if [ -z "${URL:-}" ]; then
  say "error: couldn't locate a .AppImage download URL from GitHub releases"
  say "You can manually download an AppImage from wez/wezterm releases and place it at:"
  say "  $APPIMAGE"
  exit 1
fi

say "Downloading AppImage:"
say "  $URL"

if need_cmd curl; then
  curl -fL --retry 3 --retry-delay 1 -o "$APPIMAGE" "$URL"
else
  wget -O "$APPIMAGE" "$URL"
fi

chmod +x "$APPIMAGE"

say "Extracting AppImage (avoids FUSE dependency at runtime)..."
rm -rf "$ROOT"
(
  cd "$INSTALL_DIR"
  # `--appimage-extract` works even when FUSE isn't installed.
  "$APPIMAGE" --appimage-extract >/dev/null
)

if [ ! -x "$GUI_BIN" ] && [ ! -x "$CLI_BIN" ]; then
  say "error: AppImage extracted but wezterm binary not found under: $ROOT/usr/bin"
  say "Try re-running bootstrap, or manually download a different AppImage."
  exit 1
fi

cat >"$WRAPPER" <<'SH'
#!/usr/bin/env sh
set -eu
DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CFG="$DIR/benjaminterm.lua"
GUI="$DIR/squashfs-root/usr/bin/wezterm-gui"
CLI="$DIR/squashfs-root/usr/bin/wezterm"

if [ ! -f "$CFG" ]; then
  printf '%s\n' "error: missing config at: $CFG"
  exit 1
fi

if [ -x "$GUI" ]; then
  exec "$GUI" --config-file "$CFG" "$@"
fi
if [ -x "$CLI" ]; then
  exec "$CLI" --config-file "$CFG" start "$@"
fi

printf '%s\n' "error: missing extracted wezterm binaries under: $DIR/squashfs-root/usr/bin"
printf '%s\n' "Re-run the bootstrap script to re-extract the AppImage."
exit 1
SH

chmod +x "$WRAPPER"

say "Installed launcher: $WRAPPER"

mkdir -p "$BIN_DIR"
if ln -sf "$WRAPPER" "$BIN_LINK" 2>/dev/null; then
  say "Linked command: $BIN_LINK"
else
  say "note: couldn't link $BIN_LINK (permissions?)."
  say "You can run directly: $WRAPPER"
fi

if ln -sf "$WRAPPER" "$COMPAT_BIN_LINK" 2>/dev/null; then
  say "Linked compatibility alias: $COMPAT_BIN_LINK"
else
  say "note: couldn't link compatibility alias $COMPAT_BIN_LINK"
fi

detect_os

say ""
say "Next:"
say "  benjaminterm"
if ! have_path_entry "$BIN_DIR"; then
  say ""
  say "note: $BIN_DIR is not in PATH in this shell."
  say "You can run the full path:"
  say "  $WRAPPER"
fi
say ""
say "For best paste-undo on Wayland/X11, install a clipboard helper:"
say "  sudo apt-get update && sudo apt-get install -y wl-clipboard xclip xsel"
