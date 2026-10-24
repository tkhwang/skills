---
name: tk-workflow
description: "Hub and driver for the tk staged workflow: shows where work stands, routes to the next tk-* stage, and runs the next / revise / all / slice keyword protocol."
argument-hint: "[status | start [<title> [ko|en]] | next | all | slice] [--task <slug|path>]"
disable-model-invocation: true
metadata:
  version: "0.8.0"
---

# tk-workflow

Five stages, state derived from files. One agent drives; peers join for review and debate on request. Each stage reads a document, writes a document, and ends the turn so the human approves before the next stage.

```
 [0] tk-intent ─▶ [1] tk-plan ─▶ [2] tk-implement ─▶ [3] tk-verify ─▶ [4] tk-signoff
   intent.md        plan.md,todo.md  code + todo.md      plan.md          intent → docs/intents/<ID>,
   (tasks/<slug>)   (tasks/<slug>)   checkboxes          ## Verification  specs, remove selected task
                                                                          ──▶ the human commits
```

`docs/tasks/<slug>/` holds one work item: `intent.md`, `plan.md`, `todo.md`, `baseline.md`, `reviews/` and `debates/`. Several task folders can coexist. On Go, signoff moves the intent with its Outcome to `docs/intents/<MODULE><NNN>-<slug>.md` and deletes that task's temporary artifacts. Only the intent remains as the task record; specs describe current behaviour. No completion report or plan/todo archive is created. The human commits after signoff.

`tk-grill` is the shared interview used by `tk-intent` and `tk-plan`. `tk-check` is the shared mechanical gate: it runs the repo's typecheck, lint, format, tests and build and fixes what they report; `tk-implement` calls it at every boundary, `tk-verify` in report mode, and it works on its own. `tk-intent archive` takes a dropped intent out of the flow into `archived/`. `tk-setup` writes the per-repo config. `tk-multi-review` and `tk-multi-debate` bring peer agents (claude, codex, grok) in at any gate; they read, the orchestrating agent writes.

## Config

Read `docs/agents/tk-workflow.md` first. If missing, show the defaults (single package at repo root; `docs/intents/`, `docs/specs/{module}/`, `docs/tasks/`; commands discovered from `package.json` and CI) and ask once per session whether to proceed with them, pointing at `/tk-setup`. If the folder shows several packages or repos, recommend `/tk-setup` instead of defaults.

## Task selection

Every task-aware stage and helper uses this contract, including direct slash-command calls.

- **Root and directory:** config `## Docs` → `tasks_root:` (default `docs/tasks/`) is the parent of tasks; `<tasks>` means the selected `<tasks_root>/<slug>/`, never the whole root. Paths are relative to the configured docs home. A root such as `docs/cpq-react-agent/tasks/` works the same way. An old `tasks:` config key is a fallback root when `tasks_root:` is absent.
- **Explicit selection:** `--task <slug|path>` selects a slug under the root or a task directory/artifact path there. Strip this option before parsing stage-specific arguments. A document path supplied to `tk-grill` or `tk-multi-review` also selects its containing task. Conflicting explicit selectors require clarification before any writes. Resolve paths and reject escapes outside the root, including symlink escapes; the root itself is selectable only for existing legacy flat work below.
- **Resume selection:** explicit selection → the task already selected in this conversation → the sole active task. Multiple candidates with no selection: list their paths and stages and ask which one; never choose by mtime, branch name or directory order. A selected task that disappeared does not silently switch to another. A legacy intent ID/path supplied to `tk-intent` or `tk-plan` selects the task whose plan explicitly references it; if no task does, read-only intent editing may proceed without a task, while planning must first choose a new slug folder. Never attach a legacy intent to an unrelated selected task. No candidates: delivery stages point at `tk-intent` to start one; bare `tk-intent` asks for a title and then creates a slug folder. Bare `status` may list all tasks without selecting or mutating one.
- **New work:** `start <title>` or `tk-intent <title>` creates a new task, regardless of the conversation's previous selection. Use an explicit new slug or derive a short English kebab-case slug from the title, announce it, and keep it stable even if the title changes. Slugs match `[a-z0-9]+(-[a-z0-9]+)*`; never overwrite an existing directory on creation. A collision asks whether to resume it or choose a different slug. A new path must be a direct child of the root. `start --task <new-slug>` asks for the title. Without a new-work request, a nonexistent explicit task is an error, not permission to scaffold.
- **Handoffs:** keep the resolved task path in conversation context; pass it explicitly to every invoked stage, checkpoint, grill and peer prompt. Print it with status and next commands (`/tk-plan --task tool-surface-policy`). No shared `current` file, active-task symlink or tracked task index. Approval belongs to the selected task and artifact; switching tasks does not carry approval across.
- **Isolation:** all working artifacts, including baseline, reviews and debates, stay inside `<tasks>`. Bare `plan.md` / `todo.md` in these skills mean files there. Sibling task folders are not this task's diff or cleanup scope. Slugs isolate documents, not code changes: use separate worktrees for independent concurrent code changes, and do not attribute unrelated changes in a shared checkout to this task.
- **Legacy flat work:** existing `intent.md` or a non-placeholder `plan.md` directly under the root is one candidate, selected by the root path. It may finish in place; do not migrate it or absorb sibling task folders automatically. Old placeholder files are not active work. New work always uses a slug folder. Cleanup of legacy work removes only its named workflow artifacts, never the root or its task children.
- **Standalone helpers:** `tk-grill` on a document outside the task root still works without selecting a task. `tk-check all` outside a workflow may report checks without task artifacts; `baseline`, `phase` and `slice` require a selected task. Standalone review/debate requests must select a task for their output, or explicitly supply a new `--task <slug>` to create an output-only task directory under the same slug and collision rules (an exception to the creation rule above); never write reviews/debates directly under the root or attach them to another task by guesswork.

An active candidate is a task directory containing workflow artifacts (`intent.md`, non-placeholder `plan.md`/`todo.md`, `baseline.md`, `reviews/` or `debates/`). A folder alone is not active. Derived stage and approval are separate from the session's task selection.

## State (derived, never stored)

| Observation | Stage | Next |
|---|---|---|
| no `intent.md`, `plan.md` empty | no active work | `tk-intent <title>` (scaffold) |
| `intent.md` whose human sections (Background, Goal, Success criteria, Requirements) are all empty: only the template's guide comment, blank lines, or a bare `- ` (the same test `tk-intent` uses) | intent scaffolded | the human writes the draft, then `tk-intent` |
| `intent.md` whose requirements are not all `R`-numbered with an acceptance criterion, `plan.md` empty | intent drafted | `tk-intent` (interview) |
| `intent.md` with every requirement `R`-numbered with an acceptance criterion, `plan.md` empty | intent written | `tk-plan` (which offers `tk-grill` if `## Open questions` is non-empty) |
| `plan.md` filled, 0 boxes checked in `todo.md` | plan written | `tk-implement` (`next` is the approval; asks when invoked directly) |
| some boxes checked | implementing | `tk-implement` continues |
| all boxes checked, no `## Verification` in `plan.md` | implemented | `tk-verify` |
| `## Verification` has a row whose result is `fail` (commands, behaviour checks, or `### Audit`), `stale: no` | verify failed | `tk-implement` (fixes) |
| `## Verification` has `stale: yes` (code changed after the run) | re-verify | `tk-verify` |
| `## Verification` has a `human` row for a MUST without a result | awaiting human checks | `tk-verify` (record results) |
| `## Verification` has no `### Audit` (recorded before audits existed) | re-verify | `tk-verify` |
| `## Verification` with `### Audit`, no `fail` row, `stale: no` (`note`, `discovered`, `rejected` do not block) | verified | `tk-signoff` |

The first matching row from the top wins, within the selected `<tasks>`. "Empty" means `plan.md` is missing or holds an old placeholder (`_No active work…_`). `intent.md` is the active intent, at most one per task folder. A folder containing only helper outputs has no delivery stage; report those outputs without treating it as approved work. Files under the intents path are signed off (`## Outcome`) or dropped (`archived/`) and count nowhere in this table.

Legacy: with no `intent.md`, an intent under the intents path without `## Outcome` that `plan.md` frontmatter `intent:` names (work started before intents lived in `docs/tasks/`) is the active intent, read in place by the same rows.

## Commands

**`status`** (default). With no selected task, list each active task and its derived stage. Otherwise derive the row above for the selected task, name in one line any legacy intents without `## Outcome` under the intents path, and print the next slash command. Done when the user can see stage and next step in under ten lines.

**`start [<title> [ko|en]]`**. Hand off to `tk-intent` with the arguments; without a title `tk-intent` asks for it. It copies the intent template to `docs/tasks/<slug>/intent.md` and ends the turn; the human writes the first draft, then runs `tk-intent` again.

**`next`**. Derive the stage and invoke the next skill with the Skill tool. Done when that skill has ended its turn.

## Driver protocol

Once this skill has run in a session, plain keywords continue the flow without re-typing slash commands:

| Input | Action |
|---|---|
| `다음` / `next` / `go` | Treat the current artifact as approved; invoke the next stage |
| `수정: …` / `revise: …` | Patch the current stage's artifact as asked; wait for approval again |
| `all` / `slice` | Run `tk-implement` to the end (`all`, the default) or stopping after each slice (`slice`). Either mode stops after a sub-phase that changed the database, and checkpoints every sub-phase and slice. The mode is written to `todo.md`, so `다음` resumes in it |
| `검증 [peer…]` / `verify [peer…]` | Once every box in `todo.md` is checked: run `tk-verify` as the full stage, with each named peer auditing independently; without names the current agent audits alone |
| `점검` / `check` | Run `tk-check` on the current change: the repo's typecheck, lint, format, tests and build, fixing what fails; the stage does not change |
| `리뷰 [stage] [peer…]` / `review …` | Run `tk-multi-review` on the artifact awaiting approval; the artifact stays unapproved |
| `토론 <Q<n> or sentence>` / `debate …` | Run `tk-multi-debate` on an open decision; the answer still comes from the human via `tk-grill` |
| `상태` / `status` | Re-derive state from files and report |
| `중단` / `stop` | Leave files as they are and stop driving |

Approval is explicit. "알아서 해" and "whatever you think" are delegation: offer two concrete options and ask again. "괜찮은 듯" is hedged: ask "고칠 부분이 있나요?". Only an unambiguous yes advances.

## Conventions every tk-* skill follows

- **Ask for quality, then audit it.** `tk-plan` aims for the better design, not the minimal change: it compares the current structure with current best practice, cites its sources, and writes a checkable Quality bar. `tk-implement` builds to that bar completely and cleans up at every boundary. `tk-verify` takes no checkbox, no "done" and no green run on trust: it opens the code and the tests, alone or with peers.
- **Turn boundary.** A stage saves its artifact, prints a short summary and the next command, and ends the turn. One stage per turn. A checkpoint a stage invokes mid-run (`tk-implement` → `tk-check baseline` / `phase` / `slice`, `tk-verify slice`) belongs to that stage's turn and does not end it.
- **Approval lives in conversation**, checked by the next stage at its start, never stored in files. `다음` / `next` **is** the approval: a stage entered through the driver does not ask "shall I start?" again; a stage invoked directly by its slash command does.
- **One folder per work item.** Parallel tasks use distinct stable slugs; all stages follow Task selection above. Worktrees remain useful for isolating code changes.
- **Commit after signoff.** On Go, `tk-signoff` records the concise Outcome, moves the intent under its ID, and deletes only the selected task's temporary artifacts, without placeholders or a replacement completion document. Other tasks stay untouched. The human commits the code, intent, spec updates and cleanup; no stage asks for a commit first.
- **git is read-only for the agent**: `status`, `diff`, `log`. Commits, pushes, stashes, checkouts are the human's.
- **Commands come from the repo** (config, `package.json`, CI), discovered and run by `tk-check`. Warnings fail; a tool is never silenced to pass, and what failed before the work is reported, not fixed. Run a command again only after code changed.
- **Language**: talk to the user in the config's conversation language; write documents in the config's document language; keep code, identifiers and commands untranslated.
- **Peers are read-only.** `tk-multi-*` and `tk-verify <peer…>` run other agents headless in their own processes; their output is a file under `docs/tasks/<slug>/reviews/` or `docs/tasks/<slug>/debates/`. Only the orchestrating agent edits documents or code.
- **Repo conventions win.** If the repo already lays docs out differently, follow it via `tk-setup` config.

## Verification

- [ ] Task selection was unambiguous and passed to every handoff; no shared current pointer was written.
- [ ] State was derived from the selected task's files, not from memory of the conversation.
- [ ] Completion retained only the intent as the task record, updated specs as needed, and left sibling tasks untouched.
- [ ] The next command printed matches the state table.
- [ ] No stage ran without the human's explicit approval of the previous artifact.
