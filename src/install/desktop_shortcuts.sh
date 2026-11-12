#!/usr/bin/env bash
# Puts launchers for the installed apps on the default profile's desktop.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

DESKTOP="$HOME/Desktop"
mkdir -p "$DESKTOP"

for pkg in vivaldi-stable anytype rustdesk code claude-desktop picard; do
  while read -r f; do
    [[ -n "$f" ]] || continue
    # Skip hidden helper entries such as URL handlers
    grep -q '^NoDisplay=true' "$f" && continue
    cp "$f" "$DESKTOP/"
    chmod +x "$DESKTOP/$(basename "$f")"
    echo "Added $(basename "$f") to desktop"
  done < <(launchers_for "$pkg")
done

# Herdr isn't a deb, so its launcher is added by name
cp /usr/share/applications/herdr-app.desktop "$DESKTOP/"
chmod +x "$DESKTOP/herdr-app.desktop"
echo "Added herdr-app.desktop to desktop"
