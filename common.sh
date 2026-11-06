#!/usr/bin/env bash
# Shared configuration and input checks. Requires Bash, GNU tools and flock.
KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEAM_DIR="${TEAM_DIR:-$KIT_DIR}"
if [[ -f "$TEAM_DIR/team.conf" ]]; then
  source "$TEAM_DIR/team.conf"
else
  source "$KIT_DIR/team.conf"
fi
TEAM_BOARD="${TEAM_BOARD:-$TEAM_DIR/board.md}"
export TEAM_DIR TEAM_BOARD TEAM_IDS TEAM_TZ
valid_id() {
  [[ ${1:-} =~ ^[a-z][a-z0-9_-]*$ ]] || return 1
  local member
  for member in $TEAM_IDS; do [[ $member == "${1}" ]] && return 0; done
  return 1
}
stamp() { TZ="$TEAM_TZ" date '+%Y-%m-%d %H:%M %Z'; }
clean_note() { printf '%s' "${1}" | tr '\r\n|' '   ' | sed 's/[[:space:]][[:space:]]*/ /g;s/^ //;s/ $//'; }
private_note() {
  [[ ${1} =~ [0-9]{6,} || ${1} =~ [[:alnum:]._%+-]+@([[:alnum:]-]+[.])+[[:alpha:]]{2,} ]]
}
# Call only while holding the bus lock. Reads never create the log.
current_tasks() {
  [[ -f "$TEAM_DIR/tasks.log" ]] || return 0
  awk -F ' \| ' 'NF==6 && $(2) ~ /^T[0-9]+$/ {
    if (!($(2) in row)) order[++n]=$(2); row[$(2)]=$(0)
  } END {for(i=1;i<=n;i++) print row[order[i]]}' "$TEAM_DIR/tasks.log"
}
