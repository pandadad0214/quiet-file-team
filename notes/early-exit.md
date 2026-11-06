# Early-exit block — routine template

Replace the id and paths to fit your copy of this kit. Keep all bots on one shared data directory.

```bash
export TEAM_DIR="/path/to/your/team"
result=$(bash "$TEAM_DIR/has-work.sh" helper)
printf '%s\n' "$result"
if [[ "$result" == 'NO WORK' ]]; then
  exit 0
fi
```

On exactly NO WORK, stop the entire routine: no extra tools, chat, status or board line.
Otherwise read only the referenced work and do a small batch. Log a board result only if something changed.
Do not interpret an unknown-id error as work: fix configuration first.
If a routine has independent periodic work, model that work explicitly in your scheduler or queue; do not use an empty bus check to suppress it accidentally.
