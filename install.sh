#!/bin/bash

# Installs omarchy-expanded-defaults: default-app menu entries for file
# manager/image viewer/PDF viewer/media player/mail client, and priority-
# ranked default device (camera/sound output/microphone) submenus in the
# Omarchy start menu, plus a background watcher that keeps the active device
# in sync with the priority list as hardware is plugged/unplugged.

set -euo pipefail

repo_dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
bin_target="$HOME/.local/bin"
systemd_user_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

echo "Linking scripts into $bin_target ..."
mkdir -p "$bin_target"
# Scripts resolve their own real path (readlink -f "$0") to find lib/ next to
# them, so only the entry points need linking onto PATH -- lib/ is found via
# the repo, wherever the symlink is followed from.
for script in "$repo_dir"/bin/omarchy-expanded-defaults-*; do
  ln -sf "$script" "$bin_target/$(basename "$script")"
done
chmod +x "$repo_dir"/bin/omarchy-expanded-defaults-*

echo "Adding default-app menu entries ..."
source "$repo_dir/bin/lib/common.sh"
omarchy_ed_splice_menu_block "apps" "$repo_dir/menu/omarchy-menu-extension-apps.jsonc"

echo "Building device priority menu entries ..."
omarchy_ed_ensure_store
"$bin_target/omarchy-expanded-defaults-menu-regenerate"

echo "Installing the device priority watcher service ..."
mkdir -p "$systemd_user_dir"
ln -sf "$repo_dir/systemd/omarchy-expanded-defaults-watcher.service" \
  "$systemd_user_dir/omarchy-expanded-defaults-watcher.service"
systemctl --user daemon-reload
systemctl --user enable --now omarchy-expanded-defaults-watcher.service

cat <<'EOF'

Done. Open the Omarchy start menu and look under Defaults for the new
File Manager / Image Viewer / PDF Viewer / Media Player / Mail Client
pickers, and under Defaults > Devices for the ranked Cameras / Sound
Outputs / Microphones submenus.
EOF
