#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 1
a=${1:-}; b=${2:-}
valid_id "$a" && valid_id "$b" && [[ $a != "$b" ]] || { echo 'pair: choose two different configured ids'; exit 1; }
key=$(printf '%s\n%s\n' "$a" "$b" | LC_ALL=C sort | paste -sd-)
file="$TEAM_DIR/pairs/$key.md"
if [[ ${3:-} == read ]]; then
  count=${4:-30}
  [[ $count =~ ^[1-9][0-9]*$ ]] || exit 1
  [[ ! -f $file ]] || tail -n "$count" -- "$file"
  exit 0
fi
raw=$(clean_note "${3:-}")
[[ -n $raw ]] || { echo 'pair: empty note'; exit 1; }
private_note "$raw" && { echo 'pair: note looks private; rejected'; exit 1; }
mkdir -p -- "$TEAM_DIR/pairs" || exit 1
(
  flock -w 5 9 || exit 1
  note=$raw
  if (( ${#raw} > 2000 )); then
    mkdir -p -- "$TEAM_DIR/pairs/long" || exit 1
    printf '%s | %s -> %s | %s\n' "$(stamp)" "$a" "$b" "$raw" >> "$TEAM_DIR/pairs/long/$key.md" || exit 1
    suffix=" ... full: pairs/long/$key.md"
    (( ${#suffix} < 2000 )) || exit 1
    note="${raw:0:$((2000-${#suffix}))}$suffix"
  fi
  printf '%s | %s -> %s | %s\n' "$(stamp)" "$a" "$b" "$note" >> "$file"
) 9>>"$TEAM_DIR/.bus.lock" || exit 1
echo "pair: ok ($key)"
