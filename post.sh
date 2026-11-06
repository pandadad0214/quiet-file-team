#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 1
id=${1:-}; tag=${2:-}; raw=$(clean_note "${3:-}")
valid_id "$id" || { echo 'post: unknown id; edit team.conf'; exit 1; }
case "$tag" in
  done|needs-owner|fyi|resolved) ;;
  handoff:*) valid_id "${tag#handoff:}" || { echo 'post: unknown recipient'; exit 1; } ;;
  *) echo 'post: use done, needs-owner, handoff:<id>, fyi or resolved'; exit 1 ;;
esac
[[ -n $raw ]] || { echo 'post: empty note'; exit 1; }
private_note "$raw" && { echo 'post: note looks private; rejected'; exit 1; }
mkdir -p -- "$TEAM_DIR" "$(dirname -- "$TEAM_BOARD")" || exit 1
(
  flock -w 5 9 || exit 1
  printf '%s | %s | %s | %s\n' "$(stamp)" "$id" "$tag" "${raw:0:280}" >> "$TEAM_BOARD"
) 9>>"$TEAM_DIR/.bus.lock" || exit 1
echo 'post: ok'
