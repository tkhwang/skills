---
name: tk-implement
description: "Stage [2] of the tk workflow: implement docs/tasks/todo.md task by task, completely and to the plan's Quality bar rather than minimally, checking boxes with evidence. Before the first task tk-check records a baseline of what already fails. Every Backend/Frontend sub-phase ends with a cleanup pass and a tk-check phase checkpoint (typecheck, lint, format, related tests, fixed in place), and every slice with tk-check slice and a tk-verify slice audit, each self-fixed up to three rounds. all (the default) runs to the end; slice stops after each slice. Either mode stops after a sub-phase that changed the database. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[all | slice]"
metadata:
  version: "0.5.1"
---

# tk-implement

Work the task list in order. Build each task completely, in the plan's design and to its Quality bar; verify it with its focused command; check it off with evidence; clean up and run a checkpoint at every sub-phase and slice boundary; and pause where the chosen mode or a gate says so the human can look. The agent changes code and `docs/tasks/`; it never changes git state.

Working code is not finished code. The target is what the plan asked for, built well and left clean, not the least code that turns a test green.

## Config

Read `docs/agents/tk-workflow.md` first (packages and their paths, verify commands). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

- `plan.md` is filled and `todo.md` has tasks.
- **Fix mode**: if every box is already checked and `plan.md` `## Verification` has rows whose result is `fail` (commands, behaviour checks, or `### Audit`), add to `todo.md` a `## Fixes` slice with one `### Fixes` sub-phase holding one `- [ ]` task per failing row (`covers:` the affected R-ids, `verify:` the failing command, or for an audit row the check that proves it fixed) and work those. The loop, §4 and §6 apply unchanged; §6 writes the `cleanup (final):` line again at the end of the file.
- `plan.md` Decision Log shows no open decision; otherwise stop and point at `tk-grill`.
- `plan.md` has a `## Quality bar`. A plan written without one: offer to add it through `tk-plan` (a revision; recommended), or to write it now from the repo's own conventions, each line naming the file that shows the convention, and confirm it with the human before the first task. Either way the bar is in `plan.md` before code is written.
- If no box is checked yet: entered through the driver's `다음` / `next`, that keyword is the approval; invoked directly, ask "이 plan 으로 구현을 시작할까요?" and wait for an explicit yes.
- If no box is checked yet, run `git status --porcelain` in each repository in scope (each package path's repository and the docs home's). Report uncommitted changes outside `docs/` in one line and ask whether to proceed, since they would mix into the change. Once a box is checked, uncommitted changes are this work itself, which the human commits after signoff: do not ask again. Inform only; the human owns commits.
- If no box is checked yet, write the `base:` line after `mode:` in `todo.md`: the `git rev-parse HEAD` of every repository in scope, in the format `tk-verify` §1 defines. It fixes what "the change" means for `tk-check`, `tk-verify`, `tk-signoff` and `tk-multi-review`; keep it until signoff.
- Then, still before any code changes, invoke `tk-check baseline` with the Skill tool. It runs every check on the untouched tree and writes the `baseline:` line under `base:`: what already fails is reported at every checkpoint, never fixed, and never blocks one. Report a baseline that is not clean in one line and go on; `tk-verify` records it under Discovered. Work started without a `baseline:` line keeps going without one: the tree already holds the change, and `tk-check` falls back to its no-baseline rules.

Done when approval is explicit and the starting point is known.

## 2. Mode

The mode only decides where the agent stops for the human. Both modes run the same per-task loop and the same checkpoints: `tk-check phase` at every `###` boundary, `tk-check slice` then `tk-verify slice` at every `##` boundary.

| Mode | Stops after | Typical use |
|---|---|---|
| `all` (default) | the last task only | the plan was reviewed at approval; let it run |
| `slice` | every `##` slice: Backend → Frontend in one go | see one demoable behaviour at a time |

The DB gate, the safety gates, and a checkpoint that stays red stop both modes.

The mode comes from the argument or the driver keyword; with neither, from the `mode:` line in `todo.md`; with none of those, `all`. When that line is missing or differs from the mode in use, write `mode: <mode>` on the line under the `# Todo` heading, so `다음` resumes in the same mode.

## 3. Task loop

For the next unchecked task:

1. **Frame**: restate the task, its R-ids, the decisions that constrain it, and the Quality bar lines that apply. List the error paths and edge cases the task must handle before writing code.
2. **Test first when it locks behaviour**: write or extend a test and watch it fail for the right reason. Assert the behaviour the R-id names, with expected values derived from the requirement, never copied from the code's output. Pure wiring or config: no ceremonial test.
3. **Build it completely, in the planned design.** Implement the whole behaviour: every error path and edge case from Frame, in the structure the plan's Design direction chose, to each Quality bar line that applies. Follow the plan's references and the best-structured comparable code in the repo; do not patch on top of a structure the plan decided to replace. The task's files bound the scope; what makes the test pass does not bound the quality. Better also means no speculative layers: no abstraction the plan did not choose and the code does not need.
4. **Verify**: the task's focused command, plus typecheck of the touched package. Read the output. The task must add no type error: errors that match the baseline as `tk-check` §4 classifies them are reported, and do not hold the task back. Lint, format and the wider test runs belong to `tk-check` at the sub-phase boundary; run a command again only after code changed.
5. **Check off**: `- [x] T1.1 … · evidence: <command> → <result>` in `todo.md`, at the moment it passes.
6. **Mark verification stale**: on the first code change after `plan.md` has a `## Verification` section, set its `stale: yes`. `tk-verify` must run again before signoff.

A task is done only on observed passing output, or on evidence the human pasted.

## 4. Clean up, then checkpoint

When the last task of a `###` section is checked, clean up first. Go over every file the sub-phase changed and remove or fix:

- debug output and temporary logging
- commented-out code, and comments that narrate the change instead of explaining the code
- code the work made dead: unused functions, imports, variables, exports, files, flags
- scratch scripts, temporary fixtures, generated files not meant to be committed
- `TODO` / `FIXME` that `plan.md` does not track: resolve it, or record it under `## Discovered` with its `file:line`, which makes it tracked
- duplication between this sub-phase's tasks: consolidate it into the structure the plan chose
- names that drifted from the plan, the specs, or the surrounding code

Clean what this work introduced, inside the files the plan's tasks touch; older debt in those files and mess elsewhere go to `## Discovered`. Re-run the `verify:` command of any task whose code the cleanup changed. Record one line under the `###` heading, above where the checkpoint line goes: `cleanup: <what changed, or "nothing to clean"> · YYYY-MM-DD HH:MM`.

Then invoke `tk-check phase` with the Skill tool. It applies the formatter's and linter's write modes to the sub-phase's files, runs typecheck, lint, format check, the tasks' `verify:` commands and the related tests, fixes what fails in the code (up to three rounds, never by silencing a tool), and writes the `checkpoint:` line under the `###` heading. When that section was also the last of its `##` slice, invoke `tk-check slice` (the same over the whole slice, with each touched package's test suite and the build), then `tk-verify slice`, which runs the slice's behaviour checks, audits its tasks, R-ids and tests, writes the `audit:` line, and never edits code. Each returns here. A checkpoint is part of this run, not a turn boundary: when it returns, keep working.

- **Green** → record any `discovered` items they reported under `## Discovered` (baseline failures are already in the baseline; they add nothing), then continue to the rules below.
- **`tk-check` red** → it has already used its three fix rounds, or stopped because a fix needs a file outside its scope, a decision, or one of the silencing moves it may not make. That is a safety gate: stop, show its report and raw failing output, point at what is needed.
- **`audit ✗`** → fix the failing findings inside the slice's files, then invoke `tk-check slice` and `tk-verify slice` again, up to three rounds; the repeat audit replaces the `audit:` line and re-checks only what failed and what the fix changed. A fix that needs a file outside the slice, a decision, or a fourth round is a safety gate: stop, show the findings, point at what is needed.

Then, first match wins:

- **DB gate** (both modes): the sub-phase just checked changed the database: one of its tasks carries `db: yes`, or it added or changed a migration, schema, or seed file. Report the migration files, the schema change (tables, columns, indexes, constraints), whether it was applied to the local database and how to roll it back, and what comes next. If no task carried `db: yes`, say the plan did not expect this change. End the turn. Resume on `다음`.
- **Done**: that was the last task → §6.
- **Stopping here** (`slice`, when the `###` was the last of its `##` slice): report what changed, the checkpoint lines, remaining risk, and what comes next. End the turn. Resume on `다음`.
- **Continuing** (everything else): print the checkpoint line and the next sub-phase in one line each, and go on in the same turn.

## 5. Scope discipline

Anything the plan did not ask for goes to `plan.md` `## Discovered` as `NOTICED, NOT TOUCHED: <what> · <where> · <suggested follow-up>`. Then: a small in-scope fix continues; a change that widens scope or needs a decision stops (safety gate).

Writing the task's own code well (clear names, a local helper, a cleaner function inside the planned design) is part of building it, not a scope question. A structural change the plan did not choose (a new abstraction, module boundary or pattern, or any departure from Design direction) is never built silently, however small its file footprint: if the current task cannot be done well without it, stop for a decision (the human may amend the plan); otherwise record it under Discovered. Quality inside the plan is never traded for speed; the plan is never changed silently for quality.

## Safety gates (stop in any mode)

- an open decision surfaces
- the change would exceed the plan's scope
- destructive or irreversible action (data loss, schema drop, force operations)
- external or production impact, credentials
- a verification fails and the fix needs a human decision

The DB gate is separate: it lets the sub-phase finish and pass its checkpoint, then stops (§4).

## 6. Done

When every box is checked, do a final cleanup pass over the whole change (as `tk-verify` §1 defines it: per repository, `git diff` against its `base:` entry plus untracked files): duplication across slices, leftovers from earlier sub-phases, files no task cites. Re-run the `verify:` command of any task whose code changed; when the final cleanup changed code, also invoke `tk-check` on the whole change (no scope argument), so that `tk-verify` receives a tree its commands pass. Record `cleanup (final): <what changed, or "nothing to clean"> · YYYY-MM-DD HH:MM` at the end of `todo.md`.

Then: summary of tasks, evidence, files changed, cleanup, Discovered items. Print the next command (`/tk-verify` or `다음`; `/tk-verify codex grok` or `검증 codex grok` to add independent peer audits; `리뷰` to have peers review the diff first). End the turn.

## Verification

- [ ] Each task checked only after reading passing output.
- [ ] Each task built to the Quality bar lines that apply, error paths and edge cases included, in the plan's design.
- [ ] Every `###` section carries a `cleanup:` line above its `checkpoint:` line, and `todo.md` ends with the final cleanup line.
- [ ] No `git commit`, `push`, `stash`, `checkout`, `reset` executed.
- [ ] Every `###` section and every `##` slice carries a `checkpoint:` line written by `tk-check`, and every slice an `audit:` line written by `tk-verify`; the agent continued only on green, in the same turn, and stopped only where the mode or a gate says.
- [ ] `todo.md` has a `mode:` line matching the mode this run used, and the `base:` and `baseline:` lines written when work started, before any code changed.
- [ ] No structural change the plan did not choose was built without a decision.
- [ ] Every sub-phase that changed the database ended the turn with the DB report.
- [ ] Out-of-plan findings recorded under Discovered, not fixed silently.
- [ ] `## Verification` marked `stale: yes` if it existed before this run's code changes.
