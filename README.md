# omarchy-expanded-defaults

Extends the Omarchy start menu's **Defaults** section with:

- Default-app pickers for categories Omarchy doesn't cover out of the box:
  file manager, image viewer, PDF viewer, media player, mail client.
- Ranked priority submenus for **Cameras**, **Sound Outputs**, and
  **Microphones**, plus a background watcher that automatically switches the
  active device to the highest-priority one currently connected whenever
  hardware is plugged/unplugged.

## How it works

- All of this is plain JSONC merged into `~/.config/omarchy/extensions/omarchy-menu.jsonc`
  (the same file Omarchy already documents as the user extension point for the
  start menu) — no core Omarchy files are touched, and no shell plugin/panel
  is installed.
- Static app-category entries follow the exact `when`/`checked`/`action`
  pattern used by Omarchy's built-in Browser/Editor/Terminal/Agent pickers.
- Device priority order is stored in `~/.config/omarchy/expanded-defaults/priorities.json`,
  keyed by a stable per-device identifier (PipeWire sink/source name for audio,
  udev `ID_PATH` for cameras) so ranking survives reboots and replugging into
  a different USB port order.
- The device submenus are regenerated as plain static JSONC rows (one row per
  device, one "Make Nth priority" action per rank) any time priorities change
  — there is no drag-and-drop; reordering is done by picking a device's new
  rank from its submenu.
- A `systemd --user` service (`omarchy-expanded-defaults-watcher`) watches
  `pw-dump -m` (audio) and `udevadm monitor` (cameras) and re-applies the
  highest-priority connected device whenever something changes.

## Install

```sh
./install.sh
```

This symlinks the `bin/omarchy-expanded-defaults-*` scripts onto
`~/.local/bin`, merges the menu entries into your extensions file, generates
the initial device priority menu from currently-connected hardware, and
installs + enables the watcher service. Re-running it is safe — both the
app-category block and the device block are replaced in place, not
duplicated.

Everything the installer touches is additive: your existing
`omarchy-menu.jsonc` content outside the two
`// >>> omarchy-expanded-defaults:...` / `// <<< omarchy-expanded-defaults:...`
marker blocks is left untouched.

## Uninstall

```sh
systemctl --user disable --now omarchy-expanded-defaults-watcher.service
rm ~/.config/systemd/user/omarchy-expanded-defaults-watcher.service
rm ~/.local/bin/omarchy-expanded-defaults-*
```

Then remove the two `// >>> omarchy-expanded-defaults:...` blocks from
`~/.config/omarchy/extensions/omarchy-menu.jsonc` by hand (or delete the file
if you have no other customizations in it) and, if you want, delete
`~/.config/omarchy/expanded-defaults/`.

## Known limitations

- Camera has no OS-level "default device" concept the way audio does. The
  watcher maintains a symlink at `$XDG_RUNTIME_DIR/omarchy-camera-default` →
  the highest-priority connected `/dev/videoN`; apps that don't already open
  a specific camera can be pointed at that symlink.
- Device labels come straight from PipeWire/`v4l2-ctl`, so occasionally
  generic ones (e.g. `(null)`) reflect what the hardware itself reports, not
  a bug in this tool.
- Hotplug reactions are debounced by ~1s and coalesced per device class, not
  instantaneous.
