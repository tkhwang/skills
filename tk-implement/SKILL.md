---
name: tk-implement
description: "Stage [2] of the tk workflow: implement docs/tasks/todo.md task by task, checking boxes with evidence. Every Backend/Frontend sub-phase ends with a tk-verify phase checkpoint and every slice with a tk-verify slice checkpoint, each self-fixed up to three rounds. all (the default) runs to the end; slice stops after each slice. Either mode stops after a sub-phase that changed the database. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[all | slice]"
metadata:
  version: "0.3.0"
---

# tk-implement

Work the task list in order. Verify each task with its focused command, check it off with evidence, run a checkpoint at every sub-phase and slice boundary, and pause where the chosen mode or a gate says so the human can look. The agent changes code and `docs/tasks/`; it never changes git state.

## Config

Read `docs/agents/tk-workflow.md` first (packages and their paths, verify commands). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

- `plan.md` is filled and `todo.md` has tasks.
- **Fix mode**: if every box is already checked and `plan.md` `## Verification` has failing rows, add a `## Fixes` section to `todo.md` with one task per failing row (`covers:` the affected R-ids, `verify:` the failing command) and work those; the loop below is unchanged.
- `plan.md` Decision Log shows no open decision; otherwise stop and point at `tk-grill`.
- If no box is checked yet: entered through the driver's `다음` / `next`, that keyword is the approval; invoked directly, ask "이 plan 으로 구현을 시작할까요?" and wait for an explicit yes.
- Run `git status --porcelain`. Report uncommitted changes outside `docs/` in one line and ask whether to proceed. Inform only; the human owns commits.

Done when approval is explicit and the starting point is known.

## 2. Mode

The mode only decides where the agent stops for the human. Both modes run the same per-task loop and the same checkpoints: `tk-verify phase` at every `###` boundary, `tk-verify slice` at every `##` boundary.

| Mode | Stops after | Typical use |
|---|---|---|
| `all` (default) | the last task only | the plan was reviewed at approval; let it run |
| `slice` | every `##` slice: Backend → Frontend in one go | see one demoable behaviour at a time |

The DB gate, the safety gates, and a checkpoint that stays red stop both modes.

The mode comes from the argument or the driver keyword; with neither, from the `mode:` line in `todo.md`; with none of those, `all`. When that line is missing or differs from the mode in use, write `mode: <mode>` on the line under the `# Todo` heading, so `다음` resumes in the same mode.

## 3. Task loop

For the next unchecked task:

1. **Frame**: restate the task, its R-ids, and the decisions that constrain it.
2. **Test first when it locks behaviour**: write or extend a test and watch it fail for the right reason. Pure wiring or config: no ceremonial test.
3. **Smallest change** inside the task's files. Simplest thing that works; three similar lines beat a premature abstraction.
4. **Verify**: the task's focused command, plus typecheck of the touched package. Read the output. Full suites, lint and format belong to `tk-verify`; run a command again only after code changed.
5. **Check off**: `- [x] T1.1 … · evidence: <command> → <result>` in `todo.md`, at the moment it passes.
6. **Mark verification stale**: on the first code change after `plan.md` has a `## Verification` section, set its `stale: yes`. `tk-verify` must run again before signoff.

A task is done only on observed passing output, or on evidence the human pasted.

## 4. Checkpoint

When the last task of a `###` section is checked, invoke `tk-verify phase` with the Skill tool. When that section was also the last of its `##` slice, invoke `tk-verify slice` as well. `tk-verify` runs the scoped commands, writes the `checkpoint:` line in `todo.md`, reports pass or fail with raw output, and returns here; it never edits code. A checkpoint is part of this run, not a turn boundary: when `tk-verify` returns, keep working.

- **Green** → continue to the rules below.
- **Red** → fix inside the sub-phase's (or slice's) files, then invoke the same `tk-verify` scope again, up to three rounds. A fix that needs a file outside that scope, a decision, or a fourth round is a safety gate: stop, show the raw failing output, point at what is needed.

Then, first match wins:

- **DB gate** (both modes): the sub-phase just checked changed the database: one of its tasks carries `db: yes`, or it added or changed a migration, schema, or seed file. Report the migration files, the schema change (tables, columns, indexes, constraints), whether it was applied to the local database and how to roll it back, and what comes next. If no task carried `db: yes`, say the plan did not expect this change. End the turn. Resume on `다음`.
- **Done**: that was the last task → §6.
- **Stopping here** (`slice`, when the `###` was the last of its `##` slice): report what changed, the checkpoint lines, remaining risk, and what comes next. End the turn. Resume on `다음`.
- **Continuing** (everything else): print the checkpoint line and the next sub-phase in one line each, and go on in the same turn.

## 5. Scope discipline

Anything the plan did not ask for goes to `plan.md` `## Discovered` as `NOTICED, NOT TOUCHED: <what> · <where> · <suggested follow-up>`. Then: a small in-scope fix continues; a change that widens scope or needs a decision stops (safety gate).

## Safety gates (stop in any mode)

- an open decision surfaces
- the change would exceed the plan's scope
- destructive or irreversible action (data loss, schema drop, force operations)
- external or production impact, credentials
- a verification fails and the fix needs a human decision

The DB gate is separate: it lets the sub-phase finish and pass its checkpoint, then stops (§4).

## 6. Done

When every box is checked: summary of tasks, evidence, files changed, Discovered items. Print the next command (`/tk-verify` or `다음`; `리뷰` to have peers review the diff first). End the turn.

## Verification

- [ ] Each task checked only after reading passing output.
- [ ] No `git commit`, `push`, `stash`, `checkout`, `reset` executed.
- [ ] Every `###` section and every `##` slice carries a `checkpoint:` line written by `tk-verify`; the agent continued only on green, in the same turn, and stopped only where the mode or a gate says.
- [ ] `todo.md` has a `mode:` line matching the mode this run used.
- [ ] Every sub-phase that changed the database ended the turn with the DB report.
- [ ] Out-of-plan findings recorded under Discovered, not fixed silently.
- [ ] `## Verification` marked `stale: yes` if it existed before this run's code changes.
