---
name: tk-verify
description: "Stage [3] of the tk workflow: run the repo's typecheck, lint (warnings fail), format check and tests, plus the plan's behaviour checks, and record results per R-id in plan.md. With phase or slice it is the checkpoint tk-implement calls mid-build: the same commands, scoped to what was just built, recorded in todo.md. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[phase | slice | fix]"
metadata:
  version: "0.3.0"
---

# tk-verify

Measure, then report; never fix code. Commands come from the repo and warnings count as failures. Without a scope argument this is the stage: every package, the full suite, results in `plan.md` under `## Verification` for `tk-signoff`. With `phase` or `slice` it is the checkpoint `tk-implement` calls mid-build: the same commands, scoped to what was just built, one line in `todo.md`.

## Scope

| Argument | Runs | Records | Called by |
|---|---|---|---|
| `phase` | typecheck and lint of the packages the last `###` sub-phase touched, plus that sub-phase's `verify:` commands | `checkpoint: <cmd> ✓ · <cmd> ✗ · YYYY-MM-DD HH:MM` under that `###` heading in `todo.md` | `tk-implement` at every sub-phase boundary |
| `slice` | as `phase` over the whole `##` slice, plus the plan's behaviour checks for the R-ids that slice covers, where they can run without a human | the same line under the `##` heading | `tk-implement` at every slice boundary |
| (none) | everything below, all packages | `plan.md` `## Verification` | the human or the driver after the last task |

A scoped run never touches `plan.md` and never changes the `stale:` flag. Pass or fail, it reports and returns to `tk-implement` in the same turn without ending it; fixing and deciding where to stop are `tk-implement`'s job. §5 applies to full runs only.

## Config

Read `docs/agents/tk-workflow.md` first (Verify table per package). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

Full scope: every box in `docs/tasks/todo.md` is checked; otherwise list the unchecked tasks and point at `tk-implement`. `phase` / `slice`: every box of that sub-phase or slice is checked.

## 2. Discover commands

In order: the config's Verify table → `plan.md` Verification plan → `package.json` scripts (`typecheck`, `lint`, `format`, `test`) and checked-in wrappers → what CI workflows actually run. Use the repo's own commands; add `--max-warnings 0` to eslint and `--noEmit` to tsc when the script does not already fail on warnings. Note each command's source.

Done when every package in scope has a command for typecheck, lint, format, test, or an explicit "none" with the reason.

## 3. Run

Per package in scope (full: all packages; `phase` / `slice`: the packages whose files the tasks list), in this order, reading every output. A scoped run does steps 1, 2 and the tasks' `verify:` commands; `slice` adds the runnable part of step 5 for its R-ids; format and the full suite are full-scope only.

1. typecheck (zero errors, zero warnings)
2. lint (zero warnings)
3. format check
4. full test suite, once
5. behaviour checks from the plan's Verification plan: run what can be run (CLI, HTTP, scripts); list for the human what needs a browser or a device, with exact steps and the R-id each proves.

With the `fix` argument (full scope only; `phase fix` and `slice fix` are rejected with a one-line reason, since scoped runs never change code): run the formatter's write mode and the linter's `--fix` first, then run the full sequence. Type errors and failing tests are never auto-fixed here.

## 4. Record

Scoped run: write the `checkpoint:` line in `todo.md`, report pass or fail, and return to `tk-implement`; skip §5 and do not end the turn. Full run: append or replace `## Verification` in `plan.md`:

```markdown
## Verification
run: 2026-10-10 14:02 · fix: no · stale: no

| package | check | command | result | notes |
|---|---|---|---|---|
| backend | typecheck | pnpm tsc --noEmit | pass | |
| backend | lint | pnpm eslint . --max-warnings 0 | fail | 2 warnings in src/export/csv.ts |

| R-id | behaviour check | result | evidence |
|---|---|---|---|
| R1 | 403 on foreign tenant id | pass | curl … → 403 |
| R3 | async over 100k rows | human | steps below |

### Human checks
1. … (proves R3)
```

Keep the raw output of any failing command in a fenced block under the table.

## 5. Stop (full run)

- Any `fail` → list them with the R-ids affected and point at `tk-implement`. End the turn.
- A `human` row that is the acceptance evidence for a **MUST** requirement needs a result before signoff: print the steps, ask the human to run them and report, and record `pass` / `fail` with their evidence. Until then the work is **awaiting human verification**; say so and end the turn without pointing at signoff.
- Every row `pass` (a `human` row may stay open only for a SHOULD, and is listed as such) → print the next command (`/tk-signoff` or `다음`). End the turn.

`tk-implement` sets `stale: yes` on this section when code changes after the run; a stale section means verify again.

## Verification

- [ ] Every command traced to config, scripts, or CI; none guessed.
- [ ] Warnings reported as failures.
- [ ] Results recorded in `plan.md`, not only in chat.
- [ ] No code edited beyond formatter and linter autofix under `fix`.
- [ ] A `phase` / `slice` run wrote only a `checkpoint:` line in `todo.md`, nothing in `plan.md`, and returned to `tk-implement` without ending the turn.
