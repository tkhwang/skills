---
name: tk-verify
description: "Stage [3] of the tk workflow: run the repo's typecheck, lint (warnings fail), format check and tests, plus the plan's behaviour checks, and record results per R-id in plan.md. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[fix]"
metadata:
  version: "0.1.0"
---

# tk-verify

Measure, then report. Commands come from the repo, warnings count as failures, and results land in `plan.md` under `## Verification` so `tk-signoff` can read them.

## Config

Read `docs/agents/tk-workflow.md` first (Verify table per package). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

Every box in `docs/tasks/todo.md` is checked. Otherwise list the unchecked tasks and point at `tk-implement`.

## 2. Discover commands

In order: the config's Verify table → `plan.md` Verification plan → `package.json` scripts (`typecheck`, `lint`, `format`, `test`) and checked-in wrappers → what CI workflows actually run. Use the repo's own commands; add `--max-warnings 0` to eslint and `--noEmit` to tsc when the script does not already fail on warnings. Note each command's source.

Done when every package in scope has a command for typecheck, lint, format, test, or an explicit "none" with the reason.

## 3. Run

Per package in scope, in this order, reading every output:

1. typecheck (zero errors, zero warnings)
2. lint (zero warnings)
3. format check
4. full test suite, once
5. behaviour checks from the plan's Verification plan: run what can be run (CLI, HTTP, scripts); list for the human what needs a browser or a device, with exact steps and the R-id each proves.

With the `fix` argument: run the formatter's write mode and the linter's `--fix` first, then run the full sequence. Type errors and failing tests are never auto-fixed here.

## 4. Record

Append or replace `## Verification` in `plan.md`:

```markdown
## Verification
run: 2026-10-10 14:02 · fix: no

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

## 5. Stop

All rows pass (human checks may stay `human` with steps listed) → print the next command (`/tk-signoff` or `다음`). Any `fail` → list them with the R-ids affected and point at `tk-implement`. End the turn.

## Verification

- [ ] Every command traced to config, scripts, or CI; none guessed.
- [ ] Warnings reported as failures.
- [ ] Results recorded in `plan.md`, not only in chat.
- [ ] No code edited beyond formatter and linter autofix under `fix`.
