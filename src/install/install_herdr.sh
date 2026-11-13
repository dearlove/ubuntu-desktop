#!/usr/bin/env bash
# Installs the Herdr desktop app (herdr-app) and its terminal server (herdr-core).
#
# Mirrors https://releases.herdr.dev/app/install.sh, but into the Kasm default
# profile, which Kasm copies into the user's home at session start. Both
# programs update themselves there, so they must live somewhere the user owns.
# A wrapper in /usr/local/bin and a system launcher find the user's copy.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

RELEASES=https://releases.herdr.dev
TARGET=linux-x86_64
DATA="$HOME/.local/share"
BIN="$HOME/.local/bin"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Download the current release of a Herdr component and check its checksum.
fetch_release() {
  local component="$1" out="$2" url sha
  curl -fsSL "$RELEASES/$component/latest.json" -o "$TMP/$component.json"
  url="$(jq -r --arg t "$TARGET" '.targets[$t].url // empty' "$TMP/$component.json")"
  sha="$(jq -r --arg t "$TARGET" '.targets[$t].sha256 // empty' "$TMP/$component.json")"
  if [[ -z "$url" || -z "$sha" ]]; then
    echo "No $component build for $TARGET in $RELEASES/$component/latest.json" >&2
    exit 1
  fi
  echo "Downloading $url"
  curl -fsSL "$url" -o "$out"
  echo "$sha  $out" | sha256sum -c -
}

mkdir -p "$DATA" "$BIN"

# herdr-core, with `hc` beside it as the upstream installer does
fetch_release core "$TMP/core.tar.gz"
mkdir "$TMP/core"
tar -xzf "$TMP/core.tar.gz" -C "$TMP/core"
install -m 755 "$TMP/core/herdr-core" "$BIN/herdr-core"
ln -sfn herdr-core "$BIN/hc"
"$BIN/herdr-core" --version

# herdr-app
fetch_release app "$TMP/app.tar.gz"
tar -xzf "$TMP/app.tar.gz" -C "$TMP"
rm -rf "$DATA/herdr-app"
mv "$TMP/herdr-app" "$DATA/herdr-app"
# Relative, so it still resolves once the profile is copied to /home/kasm-user
ln -sfn ../share/herdr-app/herdr-app "$BIN/herdr-app"

cat > /usr/local/bin/herdr-app <<'EOF'
#!/bin/sh
exec "$HOME/.local/share/herdr-app/herdr-app" "$@"
EOF
chmod 755 /usr/local/bin/herdr-app

install -Dm 644 "$DATA/herdr-app/herdr-app.svg" /usr/share/icons/hicolor/scalable/apps/herdr-app.svg
cat > /usr/share/applications/herdr-app.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Herdr
Comment=Terminals and coding agents that keep running
Exec=/usr/local/bin/herdr-app
Icon=herdr-app
Terminal=false
Categories=Development;
StartupWMClass=herdr-app
EOF
