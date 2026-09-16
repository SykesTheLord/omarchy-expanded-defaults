# Device enumeration helpers for omarchy-expanded-defaults. Sourced, not executed.
# Mirrors the availability/exclusion rules omarchy-audio-output-switch already
# uses, so "connected" here means the same thing it means to the existing audio
# panel and cycle command, not a reimplementation of that judgment call.

omarchy_ed_list_sinks_json() {
  local fronted
  fronted=$(omarchy-audio-tuning fronted-sink 2>/dev/null || true)
  timeout 2 pactl -f json list sinks 2>/dev/null | jq --arg fronted "$fronted" '[.[]
    | select((.ports | length == 0) or ([.ports[]? | .availability != "not available"] | any))
    | select($fronted == "" or .name != $fronted)
    | {index: .index, name: .name, description: (.description // .properties."device.description" // .name)}]'
}

# Monitor sources (the *.monitor loopback of a sink) are not microphones and
# are excluded the same way the shipped audio panel's candidateSources does.
omarchy_ed_list_sources_json() {
  timeout 2 pactl -f json list sources 2>/dev/null | jq '[.[]
    | select(.name | endswith(".monitor") | not)
    | select((.ports | length == 0) or ([.ports[]? | .availability != "not available"] | any))
    | {index: .index, name: .name, description: (.description // .properties."device.description" // .name)}]'
}

# Camera "name" for matching purposes is the udev ID_PATH of the device, which
# survives across reboots/replugs the same physical port -- unlike /dev/videoN,
# which is assigned in enumeration order and shifts as cameras are added/removed.
omarchy_ed_list_cameras_json() {
  local rows="[]"
  while IFS= read -r line; do
    [[ -z $line ]] && continue
    local dev="${line%%  *}"
    local name="${line#*  }"
    [[ $dev == /dev/video* ]] || continue
    local id
    id=$(udevadm info -q property -n "$dev" 2>/dev/null | awk -F= '$1 == "ID_PATH" { print $2; exit }')
    [[ -n $id ]] || id="$dev"
    rows=$(jq --arg id "$id" --arg name "$name" --arg dev "$dev" '. + [{id: $id, name: $name, dev: $dev}]' <<<"$rows")
  done < <(omarchy-capture-webcam-list 2>/dev/null)
  echo "$rows"
}
