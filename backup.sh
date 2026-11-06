#!/usr/bin/env bash
# Optional local snapshot; no upload, deletion or automatic scheduling.
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 1
mkdir -p -- "$TEAM_DIR/.backups" || exit 1
(
  flock -w 5 9 || exit 1
  items=()
  for name in board.md tasks.log pairs; do
    [[ ! -e "$TEAM_DIR/$name" ]] || items+=("$name")
  done
  (( ${#items[@]} )) || { echo 'backup: nothing to save'; exit 0; }
  out=$(mktemp "$TEAM_DIR/.backups/snapshot-XXXXXXXX.tar.gz") || exit 1
  tar --exclude='*.lock' -czf "$out" -C "$TEAM_DIR" "${items[@]}" || exit 1
  echo "backup: $out"
) 9>>"$TEAM_DIR/.bus.lock"
