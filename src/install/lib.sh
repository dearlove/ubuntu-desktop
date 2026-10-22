# Shared helpers for the install scripts.

# Print the .desktop launchers belonging to a package. Launcher names change
# between releases, so look in the package's file list first, then fall back
# to any launcher whose Exec runs one of the package's executables.
launchers_for() {
  local pkg="$1" found
  found="$(dpkg -L "$pkg" | grep -E '^/usr/share/applications/[^/]+\.desktop$' || true)"
  if [[ -z "$found" ]]; then
    local bins
    bins="$(dpkg -L "$pkg" | grep -E '/bin/[^/]+$' | xargs -r -n1 basename | sort -u | paste -sd'|' || true)"
    [[ -n "$bins" ]] && found="$(grep -lE "^Exec=(env [^ ]+ )*([^ ]*/)?(${bins})( |$)" /usr/share/applications/*.desktop || true)"
  fi
  [[ -n "$found" ]] && echo "$found"
  return 0
}
