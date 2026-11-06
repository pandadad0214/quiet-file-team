#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
cp -R -- "$root/." "$scratch/kit"
export TEAM_DIR="$scratch/kit" TEAM_TZ=UTC TEAM_IDS='lead builder helper'
unset TEAM_BOARD
run() { bash "$TEAM_DIR/${1}.sh" "${@:2}"; }
for file in "$TEAM_DIR"/*.sh; do bash -n "$file"; done
[[ $(run has-work helper) == 'NO WORK' ]]
run task new lead helper 'Sort a sample inbox'
run has-work helper | rg -q 'T0001.*open'
run task claim T0001 helper
run task set T0001 done helper 'Sample inbox sorted'
run post helper done 'Demo checklist updated'
run pair lead builder 'Review the demo checklist'
[[ $(run has-work helper) == 'NO WORK' ]]
run has-work builder | rg -q 'Review the demo checklist'
# A second note in the same minute is still delivered exactly once.
run pair lead builder 'Review the second demo item'
run has-work builder | rg -q 'second demo item'
[[ $(run has-work builder) == 'NO WORK' ]]
[[ $(run has-work unknown) == 'has-work: unknown id; choose an id from team.conf' ]]
# Check privacy before truncation, not just within the preview.
private=$(printf 'x%.0s' {1..300})' 123456'
if run post lead fyi "$private"; then exit 1; fi
if run pair lead builder "$private"; then exit 1; fi
if run task new lead helper "$private"; then exit 1; fi
long=$(printf 'a%.0s' {1..2200})
run pair lead builder "$long"
[[ -f "$TEAM_DIR/pairs/long/builder-lead.md" ]]
awk -F ' \| ' 'NF==3 && length($(3))>2000 {exit 1}' "$TEAM_DIR/pairs/builder-lead.md"
run task new lead helper 'Update a demo checklist'
if run task set T0002 decided builder 'Demo direction'; then exit 1; fi
run task set T0002 needs-owner helper 'Choose demo order'
run task owner | rg -q 'needs-owner'
run task set T0002 decided lead 'Use alphabetical demo order'
run task claim T0002 helper
run task set T0002 done helper 'Demo checklist complete'
# Concurrent task creation must allocate distinct ids under the bus lock.
for item in {1..8}; do run task new lead helper "Demo item ${item}" > "$scratch/result-${item}" & done
wait
[[ $(run task list helper | wc -l) -eq 8 ]]
[[ $(run task list helper | awk -F ' \| ' '{print $(2)}' | sort -u | wc -l) -eq 8 ]]
for number in {3..10}; do
  printf -v key 'T%04d' "$number"
  run task set "$key" done helper 'Demo item complete' > /dev/null
done
# Build a private-shaped string only at runtime; no contact data in fixtures.
private_contact="demo$(printf '\100')example$(printf '\056')invalid"
if run pair lead builder "$private_contact"; then exit 1; fi
export TEAM_TZ=Europe/London
run post lead fyi 'Demo zone check'
awk -F ' \| ' 'END {if ($(1) !~ / (GMT|BST)$/) exit 1}' "$TEAM_DIR/board.md"
export TEAM_TZ=UTC
# Custom board writes are also observed by the work check.
export TEAM_BOARD="$scratch/custom-board.md"
run post lead handoff:helper 'Inspect a sample item'
run has-work helper | rg -q 'Inspect a sample item'
[[ $(run has-work helper) == 'NO WORK' ]]
unset TEAM_BOARD
run backup
# A work check must not mutate any existing file except its own cursor.
before=$(cd "$TEAM_DIR" && rg --files --hidden -g '!.seen/**' -g '!.git/**' | LC_ALL=C sort | xargs sha256sum)
[[ $(run has-work helper) == 'NO WORK' ]]
after=$(cd "$TEAM_DIR" && rg --files --hidden -g '!.seen/**' -g '!.git/**' | LC_ALL=C sort | xargs sha256sum)
[[ $before == "$after" ]]
echo 'PASS: queue, board, pair, idle, cursor, privacy, overflow, role checks, custom board, backup'
