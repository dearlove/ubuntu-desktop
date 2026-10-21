#!/usr/bin/env bash
# Installs Vivaldi, Anytype, RustDesk, VS Code and Claude Desktop.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
ARCH="$(dpkg --print-architecture)"
KEYRINGS=/usr/share/keyrings
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ "$ARCH" != "amd64" ]]; then
  echo "Only amd64 is supported (got $ARCH)" >&2
  exit 1
fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg jq

# Download the newest .deb from a GitHub repo's latest release whose name matches a regex.
github_latest_deb() {
  local repo="$1" pattern="$2" out="$3" auth=() url
  if [[ -s /run/secrets/github_token ]]; then
    auth=(-H "Authorization: Bearer $(cat /run/secrets/github_token)")
  fi
  url="$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r --arg re "$pattern" '[.assets[] | select(.name | test($re))][0].browser_download_url // empty')"
  if [[ -z "$url" ]]; then
    echo "No asset matching '$pattern' in latest release of $repo" >&2
    exit 1
  fi
  echo "Downloading $url"
  curl -fsSL -o "$out" "$url"
}

# --- Apt repositories -------------------------------------------------------

# Vivaldi
curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub \
  | gpg --dearmor -o "$KEYRINGS/vivaldi.gpg"
echo "deb [arch=amd64 signed-by=$KEYRINGS/vivaldi.gpg] https://repo.vivaldi.com/archive/deb/ stable main" \
  > /etc/apt/sources.list.d/vivaldi.list

# VS Code (stop the package's postinst from adding a duplicate repo entry)
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor -o "$KEYRINGS/microsoft.gpg"
echo "deb [arch=amd64 signed-by=$KEYRINGS/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list
echo "code code/add-microsoft-repo boolean false" | debconf-set-selections

# Claude Desktop (https://code.claude.com/docs/en/desktop-linux)
curl -fsSL -o "$KEYRINGS/claude-desktop-archive-keyring.asc" https://downloads.claude.ai/claude-desktop/key.asc
gpg --show-keys --with-colons "$KEYRINGS/claude-desktop-archive-keyring.asc" \
  | grep -q '^fpr:::::::::31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE:' \
  || { echo "Claude Desktop signing key fingerprint mismatch" >&2; exit 1; }
echo "deb [arch=amd64,arm64 signed-by=$KEYRINGS/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
  > /etc/apt/sources.list.d/claude-desktop.list

# --- GitHub release packages -------------------------------------------------

github_latest_deb anyproto/anytype-ts '_amd64\.deb$' "$TMP/anytype.deb"
github_latest_deb rustdesk/rustdesk 'x86_64\.deb$' "$TMP/rustdesk.deb"

# --- Install ----------------------------------------------------------------

apt-get update
# Recommends are skipped to keep Claude's QEMU/KVM (Cowork) stack out; Cowork
# cannot run inside a Kasm container anyway. gnome-keyring lets Claude and
# VS Code store sign-ins.
apt-get install -y --no-install-recommends \
  vivaldi-stable \
  code \
  claude-desktop \
  gnome-keyring \
  libsecret-1-0 \
  "$TMP/anytype.deb" \
  "$TMP/rustdesk.deb"

# Chromium/Electron apps can't use their sandbox inside an unprivileged
# container, so launch them with --no-sandbox.
add_no_sandbox() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] || continue
    grep -q -- '--no-sandbox' "$f" && continue
    sed -i -E 's#^(Exec=[^ ]+)#\1 --no-sandbox#' "$f"
    echo "Patched $f"
  done
}
shopt -s nullglob
add_no_sandbox \
  /usr/share/applications/vivaldi*.desktop \
  /usr/share/applications/code*.desktop \
  /usr/share/applications/anytype*.desktop \
  /usr/share/applications/claude*.desktop

apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/*
