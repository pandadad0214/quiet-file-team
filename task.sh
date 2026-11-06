#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 1
cmd=${1:-}; shift || true
case "$cmd" in
  list)
    valid_id "${1:-}" || { echo 'task: unknown id'; exit 1; }
    result=$(current_tasks | awk -F ' \| ' -v id="${1}" '$(3)==id && ($(4)=="open" || $(4)=="claimed" || $(4)=="decided")')
    printf '%s\n' "${result:-task: none}"; exit 0 ;;
  owner)
    result=$(current_tasks | awk -F ' \| ' '$(4)=="needs-owner"' | sort -r)
    printf '%s\n' "${result:-task: none}"; exit 0 ;;
  stale)
    cutoff=$(TZ="$TEAM_TZ" date -d '24 hours ago' '+%Y-%m-%d %H:%M')
    result=$(current_tasks | awk -F ' \| ' -v c="$cutoff" '($(4)=="claimed" || $(4)=="blocked") && substr($(1),1,16)<c')
    printf '%s\n' "${result:-task: none}"; exit 0 ;;
  show)
    [[ ${1:-} =~ ^T[0-9]+$ ]] || exit 1
    [[ ! -f "$TEAM_DIR/tasks.log" ]] || awk -F ' \| ' -v id="${1}" '$(2)==id' "$TEAM_DIR/tasks.log"
    exit 0 ;;
  new|claim|set) ;;
  *) echo 'Usage: task.sh new <by> <owner> <title> | claim <task> <id> | set <task> <status> <by> <note> | list <id> | owner | stale | show <task>'; exit 1 ;;
esac
mkdir -p -- "$TEAM_DIR" "$(dirname -- "$TEAM_BOARD")" || exit 1
(
  flock -w 5 9 || exit 1
  if [[ $cmd == new ]]; then
    by=${1:-}; owner=${2:-}; note=$(clean_note "${3:-}"); status=open
    valid_id "$by" && valid_id "$owner" || { echo 'task: unknown id'; exit 1; }
    n=$(current_tasks | awk -F ' \| ' '{v=substr($(2),2)+0;if(v>m)m=v} END{print m+1}')
    printf -v task 'T%04d' "$n"
  else
    task=${1:-}
    [[ $task =~ ^T[0-9]+$ ]] || exit 1
    row=$(current_tasks | awk -F ' \| ' -v id="$task" '$(2)==id')
    [[ -n $row ]] || { echo 'task: no such task'; exit 1; }
    owner=$(printf '%s\n' "$row" | awk -F ' \| ' '{print $(3)}')
    old=$(printf '%s\n' "$row" | awk -F ' \| ' '{print $(4)}')
    if [[ $cmd == claim ]]; then
      by=${2:-}; status=claimed; note=claimed
      valid_id "$by" && [[ $by == "$owner" && ( $old == open || $old == decided ) ]] || { echo 'task: not claimable by this id'; exit 1; }
    else
      status=${2:-}; by=${3:-}; note=$(clean_note "${4:-}")
      valid_id "$by" || { echo 'task: unknown id'; exit 1; }
      case "$status" in
        decided) [[ $by == lead ]] || { echo 'task: only lead can mark decided'; exit 1; } ;;
        done|blocked|needs-owner|cancelled) [[ $by == "$owner" || $by == lead ]] || { echo 'task: only assignee or lead can change status'; exit 1; } ;;
        *) echo 'task: unknown status'; exit 1 ;;
      esac
      note=${note:-$status}
    fi
  fi
  [[ -n $note ]] || { echo 'task: empty note'; exit 1; }
  private_note "$note" && { echo 'task: note looks private; rejected'; exit 1; }
  note=${note:0:280}; time=$(stamp)
  printf '%s | %s | %s | %s | %s | %s\n' "$time" "$task" "$owner" "$status" "$by" "$note" >> "$TEAM_DIR/tasks.log" || exit 1
  tag=''
  [[ $cmd == new && $by != "$owner" ]] && tag="handoff:$owner"
  [[ $status == needs-owner ]] && tag=needs-owner
  if [[ -n $tag ]]; then
    printf '%s | %s | %s | %s %s\n' "$time" "$by" "$tag" "$task" "$note" >> "$TEAM_BOARD" || exit 1
  fi
  echo "task: $task $status ($owner)"
) 9>>"$TEAM_DIR/.bus.lock"
