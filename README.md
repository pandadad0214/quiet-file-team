# Quiet File Team

A file-first quiet bus for multi-bot teams: pair files, a task queue and early-exit checks so idle routines stop.

## Install / Use

This is a copy-the-folder kit of scripts, not a service. Copy this entire folder to a shared local directory such as `./team`, then run:

```bash
export TEAM_DIR="$PWD/team"
bash "$TEAM_DIR/has-work.sh" helper
```

Alternatively, clone this repository and set `TEAM_DIR` to the checkout directory:

```bash
git clone https://github.com/pandadad0214/quiet-file-team.git
export TEAM_DIR="$PWD/quiet-file-team"
```

No package registry, hosted endpoint or Release download is required.

Requirements: Linux, Bash 4 or newer, GNU core utilities, awk, sed, tar and util-linux `flock`. The test suite additionally uses ripgrep (`rg`). Scripts use local files on one shared computer. Network filesystems with unreliable locks are not supported. The kit does not install or schedule routines for you.

## Setup guide

1. Copy the whole tree to a shared local folder. Keep its scripts and `team.conf` together.
2. Edit the example roster in `team.conf`: `lead builder helper`. Use lowercase ids made of letters, digits, underscores and hyphens, starting with a letter. Keep ids short so pair filenames fit the filesystem. `lead` is the example coordinator with the decided action; if you rename it, update that role check in `task.sh` too.
3. Set `TEAM_TZ` in the config or environment. Its default is `UTC`; choose a zone supported by your system, such as `Europe/London`. Stamps have the form `YYYY-MM-DD HH:MM TZ`. Do not change zones midway through existing logs; stale checks compare local wall-clock stamps and are approximate across daylight-saving changes.
4. Give each bot the [core rules](notes/core-rules.md). Paste the [early-exit block](notes/early-exit.md) into every routine, replacing the id and path. Ensure the routine really stops on exactly `NO WORK`.
5. Run the scripts once with the fictional exercise below. Customize [context files](notes/handover-template.md) and remove the demo prose when ready.

```bash
export TEAM_DIR="$PWD/team"
bash "$TEAM_DIR/task.sh" new lead helper "Sort a sample inbox"
bash "$TEAM_DIR/task.sh" claim T0001 helper
bash "$TEAM_DIR/task.sh" set T0001 done helper "Sample inbox sorted"
bash "$TEAM_DIR/post.sh" helper done "Demo checklist updated"
bash "$TEAM_DIR/pair.sh" lead builder "Review the demo checklist"
bash "$TEAM_DIR/has-work.sh" helper
# NO WORK
```

These commands assume an untouched demo log. Use the task id printed by `new` if the folder already contains tasks. The pair note gives builder work, not helper. Do not run the demo against a production data folder.

## How the method works

Each bot's chat is for the owner. Bots do not message each other unless the owner asks by name. A shared computer plus files is the bus; there are no background listeners or hidden chat channels.

Every routine starts with `has-work.sh <id>`. Exactly `NO WORK` means stop: no chat, no status, no board line. Otherwise pick up only the listed work. Open, claimed and decided tasks remain visible each run until their state changes. Pair notes and direct board handoffs are delivered once per cursor. Task-generated handoffs are represented by the task queue rather than repeated as board work.

- **Pair files:** `pairs/<sorted-ids>.md` hold short, directed handoffs. Notes over the cap of 2000 characters get an overflow file under `pairs/long/` with a pointer. Read it when referenced.
- **Task queue:** `tasks.log` is append-only. The latest event for a task is its state. `new` creates an open task, the assignee `claim`s it, and `set` records progress. States include `open`, `claimed`, `done`, `blocked`, `needs-owner`, `decided` and `cancelled`. Only `lead` can set `decided`; only the assignee or `lead` can set the other update states. The `owner` command lists questions waiting for the owner. Blocked and owner-wait tasks are not routine pickup work; review them with `stale` or `owner`.
- **Board:** `board.md` is an append-only summary, updated via `post.sh`; it is not a transcript.
- **Context:** short `notes/<id>-context.md` files keep durable next steps without old chat history.

The scripts serialize mutations using `flock`. Board notes, task titles and task update notes are capped at 280 characters. All text is checked before truncation or overflow storage for long digit strings and email-shaped content. These checks are a rough guardrail, not a secret detector. Never put private data in this bus.

`has-work.sh` only writes `.seen/<id>` (creating its parent directory if necessary); it does not append logs or make lock files. It uses per-file line counts to avoid missing messages written within the same minute. Do not rotate or rewrite logs during use. Run only one routine at a time per id. The cursor means “observed”, not “completed”: create a task for any handoff that must survive a crash or a failed run.

## How we cut token use

- Early-exit before loading context when there is no work.
- No idle chat or repeated status updates.
- Short context files instead of replaying transcripts.
- Batch owner questions rather than repeated interruptions.
- File-first handoffs with links to detail only when needed.

These are operating practices, not measured savings or a promise of a particular reduction.

## Free vs paid editions

This public repository is the free core. Clone or copy it and follow the setup guide above; no purchase is needed.

### Free MCP companion

Six offline guidance tools for the same method (explain the method, draft safe team configuration and early-exit text, validate a supplied layout, draft a fictional workflow, batch explicit owner questions):

- Repository: https://github.com/pandadad0214/quiet-file-team-mcp
- Install: `uvx --from git+https://github.com/pandadad0214/quiet-file-team-mcp.git@v0.1.0 quiet-file-team-mcp`

The MCP tools are free offline guidance. They do not read arbitrary files, call the network, charge for runs or schedule routines.

### Paid setup kit (live on Agensi)

Ready rules, guided installation, acceptance checks and fictional practice are available as a one-time Agensi skill:

- Listing: https://agensi.io/skills/quiet-file-team-setup-kit ($29 one-time)

**Free → paid skill:** keep this free core, load the Agensi skill guidance in your agent, apply selected rule packs, practice in a new folder and complete the acceptance checklist. Do not replace operational logs with examples.

**Paid → free:** retain your scripts, remove optional kit rules and continue with this README. For a clean copy, clone this repository separately, back up current data and deliberately review or re-enter active tasks; never merge cursors blindly.

An Apify Actor that generates a configured core-plus-guidance ZIP is built and queued for Store publication; it is **not purchasable on Apify yet**. When the Store listing goes public it will be linked here with the same switch steps. No other purchasable edition is claimed.

## What this is not

- Not a hosted chat bus or an LLM.
- Not a replacement for the owner's chat.
- Not a way for bots to talk behind the owner's back.
- Not authentication, access control or encrypted storage. Ids label records; they do not prove identity. All local users who can access these files may read or alter them. Use an appropriately restricted local directory.
- Not itself an MCP server or an Apify Actor. A free companion MCP lives at https://github.com/pandadad0214/quiet-file-team-mcp; a paid Agensi setup skill is linked above. An Apify Store generator is queued and not purchasable yet.

## For developers

| File | Purpose |
| --- | --- |
| `has-work.sh <id>` | Print pending work or exactly `NO WORK`; always exit successfully, including friendly unknown-id errors |
| `pair.sh <from> <to> <note>` | Append a directed pair note; `read [count]` reads recent lines |
| `post.sh <id> <tag> <note>` | Append `done`, `needs-owner`, `handoff:<id>`, `fyi` or `resolved` |
| `task.sh` | `new`, `claim`, `set`, `list`, `owner`, `stale`, `show` |
| `backup.sh` | Optional local snapshot of board, task log and pairs; no upload or automatic deletion |
| `common.sh` / `team.conf` | Shared helpers and the editable example roster |
| `tests/smoke.sh` | Run isolated tests against a temporary copy |

`TEAM_DIR` defaults to the directory containing the scripts. It can point to a separate data folder; its `team.conf` takes precedence if present, otherwise the script folder's config is used. `TEAM_IDS` and `TEAM_TZ` can be set in the environment; defaults are `lead builder helper` and `UTC`. `TEAM_BOARD` overrides the board path for both writers and readers. The optional backup covers the default `board.md` only; back up a custom external board separately. Backup archives stay in `.backups/` until you manage their retention.

Mutation commands return nonzero on errors. `has-work.sh` always exits zero, so consumers must check the output, not just the exit status. A board write can fail after a task event is saved: inspect `task.sh show` before retrying task creation. Configuration files are trusted shell code; do not source untrusted config files.

### Contributing

Keep changes generic and examples fictional. Do not submit personal data or secrets. Preserve append-only behavior, configurable paths, quiet idle runs and the single editable roster. Run `bash tests/smoke.sh`, `bash -n` on each script, and ShellCheck when available. Tests must never touch an existing team's data.

Suggested topics: `multi-agent`, `automation`, `routines`, `file-based`, `team-coordination`.

MIT licensed; see [LICENSE](LICENSE).
