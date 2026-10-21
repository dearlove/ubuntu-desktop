#!/usr/bin/env bash
# Puts launchers for the installed apps on the default profile's desktop.
set -euo pipefail
shopt -s nullglob

DESKTOP="$HOME/Desktop"
mkdir -p "$DESKTOP"

for pattern in vivaldi-stable anytype rustdesk code claude; do
  for f in /usr/share/applications/${pattern}*.desktop; do
    # Skip URL-handler helpers such as code-url-handler.desktop and rustdesk-link.desktop
    [[ "$f" == *url-handler* || "$f" == *-link.desktop ]] && continue
    cp "$f" "$DESKTOP/"
    chmod +x "$DESKTOP/$(basename "$f")"
    echo "Added $(basename "$f") to desktop"
  done
done
