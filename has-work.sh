#!/usr/bin/env bash
# Read-only except for the cursor file .seen/<id>. Always returns success.
trap 'exit 0' EXIT
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 0
id=${1:-}
valid_id "$id" || { echo 'has-work: unknown id; choose an id from team.conf'; exit 0; }
cursor="$TEAM_DIR/.seen/$id"
# Line counts avoid missing messages written within the same minute.
declare -A previous
if [[ -f $cursor ]]; then
  while IFS=$'\t' read -r key count; do
    [[ $count =~ ^[0-9]+$ ]] && previous["$key"]=$count
  done < "$cursor"
fi
state=''; messages=''
inspect() {
  local path=${1} key=${2} mode=${3} count start found
  [[ -f $path ]] || return 0
  count=$(awk 'END{print NR+0}' "$path")
  start=${previous[$key]:-0}
  # If a file was manually reset, treat the current contents as new.
  (( start <= count )) || start=0
  found=$(awk -F ' \| ' -v start="$start" -v end="$count" -v me="$id" -v mode="$mode" -v key="$key" '
    NR>start && NR<=end {
      if(mode=="board" && $(3)=="handoff:" me && $(4) !~ /^T[0-9]+ /) print key ": " $(0)
      if(mode=="pair" && $(2) ~ (" -> " me "$")) print key ": " $(0)
    }' "$path")
  [[ -z $found ]] || messages+="$found"$'\n'
  state+="$key"$'\t'"$count"$'\n'
}
inspect "$TEAM_BOARD" board board
for path in "$TEAM_DIR"/pairs/*.md; do
  name=${path##*/}
  case "$name" in "$id"-*.md|*-"$id".md) inspect "$path" "pairs/$name" pair ;; esac
done
tasks=$(current_tasks | awk -F ' \| ' -v me="$id" '$(3)==me && ($(4)=="open" || $(4)=="claimed" || $(4)=="decided")')
# No task, board, pair or lock file is created by this script.
if mkdir -p -- "$TEAM_DIR/.seen" 2>/dev/null; then
  printf '%s' "$state" > "$cursor" 2>/dev/null || true
fi
if [[ -z $tasks && -z $messages ]]; then
  echo 'NO WORK'
else
  [[ -z $tasks ]] || printf 'TASKS:\n%s\n' "$tasks"
  [[ -z $messages ]] || printf 'HANDOFFS:\n%s' "$messages"
fi
exit 0
