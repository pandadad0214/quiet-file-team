# Quiet File Team

Quiet File Team lets several AI bots share one computer through plain files, so idle routines stop on `NO WORK` instead of spending tokens. It is a free, MIT-licensed Bash kit (pair notes, an append-only task queue, a board and an early-exit check) with no server, chat bus or LLM inside.

[![Latest Release](https://img.shields.io/github/v/release/pandadad0214/quiet-file-team?label=latest%20release)](https://github.com/pandadad0214/quiet-file-team/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## Part of [Panda Federation](https://pandafederation.com/)

[![Part of Panda Federation](https://pandafederation.com/assets/badge.svg)](https://pandafederation.com/)

This project is a module of the Panda Federation — public-data tools, MCP servers, and local-first apps in one catalog. See the rest of the work, including books when they publish and the matching free or paid editions of this tool, at the [official site](https://pandafederation.com/).

Follow on X: [@PandaFedHQ](https://x.com/PandaFedHQ)

## How to use this

```bash
curl -fsSL https://github.com/pandadad0214/quiet-file-team/archive/refs/tags/v0.1.0.tar.gz | tar xz && mv quiet-file-team-0.1.0 team
export TEAM_DIR="$PWD/team"
bash "$TEAM_DIR/has-work.sh" helper   # a fresh kit prints: NO WORK
```

1. **Copy the kit** into a shared local folder with the command above (or `git clone https://github.com/pandadad0214/quiet-file-team.git team`).
2. **Name your bots** in `team/team.conf` (`TEAM_IDS="lead builder helper"`) and set `TEAM_TZ` (default `UTC`).
3. **Start every routine** with `bash "$TEAM_DIR/has-work.sh" <id>` and stop the routine when it prints exactly `NO WORK`.

Then run the practice exercise in the [setup guide](#setup-guide), give each bot the [core rules](notes/core-rules.md) and paste the [early-exit block](notes/early-exit.md) into each routine. Want it configured for you? See [Editions and how to switch](#editions-and-how-to-switch).

### What a run looks like

```text
$ bash task.sh new lead helper "Sort a sample inbox"
task: T0001 open (helper)
$ bash pair.sh lead helper "Sample inbox is in notes/"
pair: ok (helper-lead)
$ bash has-work.sh helper
TASKS:
2026-11-09 16:53 UTC | T0001 | helper | open | lead | Sort a sample inbox
HANDOFFS:
pairs/helper-lead.md: 2026-11-09 16:53 UTC | lead -> helper | Sample inbox is in notes/
```

## For AI agents

| Field | Value |
| --- | --- |
| Purpose | File-first coordination for several bots on one computer: pair notes, task queue, board and an early-exit check. |
| Use when | Two or more bots or scheduled routines share one machine and you want idle runs to exit early and handoffs to live in files. |
| Do not use when | Bots run on different machines without a shared local disk, you need authentication or encryption, or you need real-time chat. |
| Install | `curl -fsSL https://github.com/pandadad0214/quiet-file-team/archive/refs/tags/v0.1.0.tar.gz \| tar xz` or `git clone`; no package registry. |
| Entry point | `has-work.sh <id>`: prints pending `TASKS:` / `HANDOFFS:` or exactly `NO WORK`; always exits 0, so check the output. |
| Write commands | `task.sh new\|claim\|set\|list\|owner\|stale\|show`, `pair.sh <from> <to> <note>`, `post.sh <id> <tag> <note>` |
| State files | `tasks.log` (append-only), `board.md`, `pairs/*.md`, `.seen/<id>`, `notes/<id>-context.md` |
| Side effects | Local file writes only. No network, no scheduler, no model calls. |
| Requirements | Linux, Bash 4+, GNU coreutils, awk, sed, tar, util-linux `flock` |
| Related | Free MCP companion `quiet-file-team-mcp`; paid setup kit on Agensi and Apify (see editions below). |

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

## Editions and how to switch

| Edition | What you get | Price | Start here |
| --- | --- | --- | --- |
| Free core (this repo) | The Bash scripts, demo roster, rules and early-exit text | Free | [How to use this](#how-to-use-this) |
| Free MCP companion | Six offline guidance tools: explain the method, draft team config and early-exit text, validate a layout, draft a fictional workflow, batch owner questions | Free | [quiet-file-team-mcp](https://github.com/pandadad0214/quiet-file-team-mcp) |
| Agensi setup kit skill | Ready rules, guided installation, acceptance checks and fictional practice, loaded into your agent | $29 one-time | [agensi.io/skills/quiet-file-team-setup-kit](https://agensi.io/skills/quiet-file-team-setup-kit) |
| Apify setup kit generator | A configured core-plus-guidance ZIP built from your roster, time zone and coordinator id | $29 per generated kit | [apify.com/pandadad0214/quiet-file-team-setup](https://apify.com/pandadad0214/quiet-file-team-setup) |

- **Free core → free MCP:** keep this folder, then add the companion to your MCP client with `uvx --from git+https://github.com/pandadad0214/quiet-file-team-mcp.git@v0.1.0 quiet-file-team-mcp`. It never reads your files or calls the network.
- **Free core → Agensi skill:** keep this folder, load the Agensi skill in your agent, apply the rule packs you want, practice in a new folder and finish the acceptance checklist. Do not replace operational logs with examples.
- **Free core → Apify generator:** on the Actor page fill **Roster** (`TEAM_IDS`, e.g. `lead builder helper`), **IANA time zone** (`TEAM_TZ`) and **Coordinator** (`lead`), allow a maximum run charge of at least $29, then Start. Download **OUTPUT.zip** from the run's key-value store and unpack it into a new folder; move live tasks over by hand.
- **Agensi ↔ Apify:** the skill guides an agent through setup in your own folder; the Actor hands you a ready ZIP. Use the skill if your agent will do the install, the Actor if you want files only.
- **Paid → free:** keep your scripts, drop the optional kit rules and continue with this README. For a clean copy, clone this repository separately, back up current data and re-enter active tasks deliberately; never merge `.seen` cursors blindly.

## What this is not

- Not a hosted chat bus or an LLM.
- Not a replacement for the owner's chat.
- Not a way for bots to talk behind the owner's back.
- Not authentication, access control or encrypted storage. Ids label records; they do not prove identity. All local users who can access these files may read or alter them. Use an appropriately restricted local directory.
- Not itself an MCP server or an Apify Actor. The free MCP companion and the paid Agensi and Apify setup kits are linked in [Editions and how to switch](#editions-and-how-to-switch).

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
