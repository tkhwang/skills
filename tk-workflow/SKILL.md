---
name: tk-workflow
description: "Hub and driver for the tk staged workflow: shows where work stands, routes to the next tk-* stage, and runs the next / revise / all / slice keyword protocol."
argument-hint: "[status | start [<MODULE> <title> [ko|en]] | next | all | slice]"
disable-model-invocation: true
metadata:
  version: "0.4.0"
---

# tk-workflow

Five stages, state derived from files. One agent drives; peers join for review and debate on request. Each stage reads a document, writes a document, and ends the turn so the human approves before the next stage.

```
 [0] tk-intent ─▶ [1] tk-plan ─▶ [2] tk-implement ─▶ [3] tk-verify ─▶ [4] tk-signoff
   docs/intents     docs/tasks       code + todo.md      plan.md          intent Outcome,
   (permanent)      plan.md,todo.md  checkboxes          ## Verification  specs, empty tasks
```

`tk-grill` is the shared interview used by `tk-intent` and `tk-plan`. `tk-setup` writes the per-repo config. `tk-multi-review` and `tk-multi-debate` bring peer agents (claude, codex, grok) in at any gate; they read, the orchestrating agent writes.

## Config

Read `docs/agents/tk-workflow.md` first. If missing, show the defaults (single package at repo root; `docs/intents/`, `docs/specs/{module}/`, `docs/tasks/`; commands discovered from `package.json` and CI) and ask once per session whether to proceed with them, pointing at `/tk-setup`. If the folder shows several packages or repos, recommend `/tk-setup` instead of defaults.

## State (derived, never stored)

| Observation | Stage | Next |
|---|---|---|
| `plan.md` empty, no intent file at all | before start | `tk-intent <MODULE> <title>` (scaffold) |
| intent without `## Outcome` whose human sections (Background, Goal, Success criteria, Requirements) are all empty: only the template's guide comment, blank lines, or a bare `- ` (the same test `tk-intent` uses) | intent scaffolded | the human writes the draft, then `tk-intent <ID>` |
| `plan.md` empty, every intent has `## Outcome` | done | new intent (`tk-intent`) |
| intent without `## Outcome` whose requirements are not all `R`-numbered with an acceptance criterion, `plan.md` empty | intent drafted | `tk-intent` (interview) |
| intent without `## Outcome`, every requirement `R`-numbered with an acceptance criterion, `plan.md` empty | intent written | `tk-plan` (which offers `tk-grill` if `## Open questions` is non-empty) |
| `plan.md` filled, 0 boxes checked in `todo.md` | plan written | `tk-implement` (`next` is the approval; asks when invoked directly) |
| some boxes checked | implementing | `tk-implement` continues |
| all boxes checked, no `## Verification` in `plan.md` | implemented | `tk-verify` |
| `## Verification` has a failing row, `stale: no` | verify failed | `tk-implement` (fixes) |
| `## Verification` has `stale: yes` (code changed after the run) | re-verify | `tk-verify` |
| `## Verification` has a `human` row for a MUST without a result | awaiting human checks | `tk-verify` (record results) |
| `## Verification` all pass, `stale: no` | verified | `tk-signoff` |

The first matching row from the top wins. "Empty" means `plan.md` is missing or holds only the placeholder `tk-signoff` writes (`_No active work…_`). `plan.md` frontmatter `intent:` names the active intent (`AGENT001-tenant-export`). Several intents may exist without Outcome; the active one is the one `plan.md` names.

## Commands

**`status`** (default). Derive the row above for the active intent, list other intents without Outcome, and print the next slash command. Done when the user can see stage and next step in under ten lines.

**`start [<MODULE> <title> [ko|en]]`**. Hand off to `tk-intent` with the arguments; without them `tk-intent` asks module, title and language. It copies the intent template to a new file and ends the turn; the human writes the first draft, then runs `tk-intent <ID>`.

**`next`**. Derive the stage and invoke the next skill with the Skill tool. Done when that skill has ended its turn.

## Driver protocol

Once this skill has run in a session, plain keywords continue the flow without re-typing slash commands:

| Input | Action |
|---|---|
| `다음` / `next` / `go` | Treat the current artifact as approved; invoke the next stage |
| `수정: …` / `revise: …` | Patch the current stage's artifact as asked; wait for approval again |
| `all` / `slice` | Run `tk-implement` to the end (`all`, the default) or stopping after each slice (`slice`). Either mode stops after a sub-phase that changed the database, and checkpoints every sub-phase and slice. The mode is written to `todo.md`, so `다음` resumes in it |
| `리뷰 [stage] [peer…]` / `review …` | Run `tk-multi-review` on the artifact awaiting approval; the artifact stays unapproved |
| `토론 <Q<n> or sentence>` / `debate …` | Run `tk-multi-debate` on an open decision; the answer still comes from the human via `tk-grill` |
| `상태` / `status` | Re-derive state from files and report |
| `중단` / `stop` | Leave files as they are and stop driving |

Approval is explicit. "알아서 해" and "whatever you think" are delegation: offer two concrete options and ask again. "괜찮은 듯" is hedged: ask "고칠 부분이 있나요?". Only an unambiguous yes advances.

## Conventions every tk-* skill follows

- **Turn boundary.** A stage saves its artifact, prints a short summary and the next command, and ends the turn. One stage per turn. A checkpoint a stage invokes mid-run (`tk-implement` → `tk-verify phase` / `slice`) belongs to that stage's turn and does not end it.
- **Approval lives in conversation**, checked by the next stage at its start, never stored in files. `다음` / `next` **is** the approval: a stage entered through the driver does not ask "shall I start?" again; a stage invoked directly by its slash command does.
- **One active work item.** Parallel work uses git worktrees, which gives each its own `plan.md`.
- **git is read-only for the agent**: `status`, `diff`, `log`. Commits, pushes, stashes, checkouts are the human's.
- **Commands come from the repo** (config, `package.json`, CI). Run a command again only after code changed.
- **Language**: talk to the user in the config's conversation language; write documents in the config's document language; keep code, identifiers and commands untranslated.
- **Peers are read-only.** `tk-multi-*` run other agents headless in their own processes; their output is a file under `docs/tasks/reviews/` or `docs/tasks/debates/`. Only the orchestrating agent edits documents or code.
- **Repo conventions win.** If the repo already lays docs out differently, follow it via `tk-setup` config.

## Verification

- [ ] State was derived from files, not from memory of the conversation.
- [ ] The next command printed matches the state table.
- [ ] No stage ran without the human's explicit approval of the previous artifact.
