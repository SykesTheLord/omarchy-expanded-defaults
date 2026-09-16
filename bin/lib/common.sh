# Shared helpers for omarchy-expanded-defaults scripts. Sourced, not executed.

OMARCHY_ED_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/expanded-defaults"
OMARCHY_ED_PRIORITIES="$OMARCHY_ED_CONFIG_DIR/priorities.json"
OMARCHY_ED_MENU_EXT="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/extensions/omarchy-menu.jsonc"
OMARCHY_ED_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
OMARCHY_ED_CAMERA_LINK="$OMARCHY_ED_RUNTIME_DIR/omarchy-camera-default"

omarchy_ed_ensure_store() {
  mkdir -p "$OMARCHY_ED_CONFIG_DIR"
  [[ -f "$OMARCHY_ED_PRIORITIES" ]] || printf '{"sinks":[],"sources":[],"cameras":[]}' >"$OMARCHY_ED_PRIORITIES"
}

# Splices a generated block into the user's menu extensions JSONC file between
# marker comments, leaving everything else in the file untouched. JSONC here
# tolerates trailing commas, so every generated entry line can safely end in
# one without having to special-case the last line.
omarchy_ed_splice_menu_block() {
  local marker="$1" content_file="$2"
  local begin="// >>> omarchy-expanded-defaults:${marker} (auto-generated, do not edit by hand)"
  local end="// <<< omarchy-expanded-defaults:${marker}"

  mkdir -p "$(dirname "$OMARCHY_ED_MENU_EXT")"
  [[ -f "$OMARCHY_ED_MENU_EXT" ]] || printf '{\n}\n' >"$OMARCHY_ED_MENU_EXT"

  local tmp
  tmp=$(mktemp)

  awk -v begin="$begin" -v end="$end" -v contentfile="$content_file" '
    BEGIN { skipping = 0; inserted = 0 }
    $0 == begin { print; while ((getline line < contentfile) > 0) print line; close(contentfile); inserted = 1; skipping = 1; next }
    $0 == end { skipping = 0; print; next }
    skipping { next }
    /^\}[[:space:]]*$/ && !inserted {
      print begin
      while ((getline line < contentfile) > 0) print line
      close(contentfile)
      print end
      inserted = 1
      print
      next
    }
    { print }
  ' "$OMARCHY_ED_MENU_EXT" >"$tmp"

  mv "$tmp" "$OMARCHY_ED_MENU_EXT"
}

omarchy_ed_notify() {
  command -v omarchy-notification-send &>/dev/null && omarchy-notification-send -g "$1" "$2"
}
