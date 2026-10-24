---
name: tk-check
description: "Run the repo's own typecheck, lint (warnings fail), format check, tests and build on the current change; apply the formatter's and linter's write modes, then fix what still fails in the code itself, never by silencing a tool, up to three rounds. Failures that predate the change are reported, never fixed. tk-implement calls it before the first task (baseline) and at every sub-phase and slice boundary (phase, slice), tk-verify calls it to measure (all report), and it works on its own after any code change. Use when the user asks to check, lint, format, typecheck or test the change, or a tk-* stage calls it."
argument-hint: "[phase | slice | all | baseline] [report | autofix] [--task <slug|path>]"
metadata:
  version: "0.2.0"
---

# tk-check

The mechanical gate: the repo's own tools, run over what changed, warnings counted as failures. What a tool can fix in its write mode, the tool fixes; what is left, the agent fixes in the code. A tool's output is a fact, not a judgement, so one skill both measures and fixes it. Whether the work meets the plan is a judgement: that is `tk-verify`'s audit, which never fixes.

## Scope

| Argument | Lint and format | Tests | Records | Called by |
|---|---|---|---|---|
| (none) | the files of the change | the suite of every package the change touches | the report, in chat | the human, after any code change; `tk-implement` after its final cleanup |
| `phase` | the change, narrowed to the last `###` sub-phase | its tasks' `verify:` commands and the tests related to its files | `checkpoint:` line under that `###` heading in `todo.md` | `tk-implement` at every sub-phase boundary |
| `slice` | the change, narrowed to the `##` slice | the suite of every package the slice touches | `checkpoint:` line under that `##` heading | `tk-implement` at every slice boundary, before `tk-verify slice` |
| `all` | every package, as CI runs them | every package's full suite, once | the report, returned to `tk-verify` | `tk-verify` on a full run |
| `baseline` | every package, before any code changes | every package's full suite | `baseline:` line in `todo.md`, entries in `<tasks>/baseline.md` | `tk-implement` before the first task |

Typecheck and build always run per package. Build runs on every scope except `phase`.

| Level | Write modes (§3) | Code fixes (§5) | Used by |
|---|---|---|---|
| `fix` (default) | yes | yes | `tk-implement`, the human |
| `autofix` | yes | no | `tk-verify fix` |
| `report` | no | no | `tk-verify`; always on `baseline`, which never changes a file |

**Turn.** Called by a stage (`tk-implement`, `tk-verify`), it reports and returns to that stage in the same turn, pass or fail; deciding where to stop is the caller's job. Run by the human, it ends the turn with the report.

## Task context

Before reading or writing workflow artifacts, follow [tk-workflow Task selection](../tk-workflow/SKILL.md#task-selection). Accept `--task <slug|path>`; `<tasks>` is the resolved selected task directory, not the tasks root. Pass that path to every nested skill and peer, and include it in the next command. Standalone helper exceptions are defined there.

## Config

Read `docs/agents/tk-workflow.md` first: the packages and their paths, the Verify table, the tasks root (`tasks_root:`, default `docs/tasks/`). If it is missing, discover the commands (§2), show them in the report, and point at `/tk-setup` once per session; do not stop.

## 1. The change

The change is the one `tk-verify` §1 defines: per repository in scope, `git diff <base>` plus untracked files, with `<base>` from the `base:` line in `todo.md`, else the merge-base of `HEAD` and the default branch. Outside the tk workflow (no `todo.md`) the same fallback applies; on the default branch itself that is the uncommitted work.

- **Files in scope**: the change's added and modified files that still exist, never deleted paths. `phase` / `slice` narrow them to the files the tasks of that sub-phase or slice list, plus any other file the work on those tasks edited.
- **Packages in scope**: every package whose path holds a file in scope; on `all` and `baseline`, every package.

Nothing in scope: report "nothing to check" and return.

## 2. Discover commands

In order: the config's Verify table → `plan.md` Verification plan → `package.json` scripts (or `pyproject.toml`, `Makefile`, …) and checked-in wrappers → what CI workflows actually run. Per package: typecheck, lint, format check and test; and where the repo has them, build, the write modes (`fix`) and a related-tests mode. Use the repo's own commands; add `--max-warnings 0` to eslint and `--noEmit` to tsc when the script does not already fail on warnings. Note each command's source. Never install a tool or a dependency to get a command.

- **File lists.** A scoped lint, format or write run calls the tool with the repo's config on the files (`pnpm exec eslint --max-warnings 0 <files>`, `pnpm exec prettier --check --ignore-unknown <files>`), not a script that hardcodes `.`. Pass only files the tool handles; eslint 9 also takes `--no-warn-ignored`, since an ignored file passed by name is itself a warning.
- **Write modes** are the checking tools' own: `eslint --fix`, `prettier --write`, `biome check --write`, `ruff check --fix` and `ruff format`, `gofmt -w`. Never a tool the check does not use.
- **Related tests**: the runner's own mode (`vitest related --run <files>`, `jest --findRelatedTests <files>`). Without one, `phase` runs only its tasks' `verify:` commands.

Done when every package in scope has a command for typecheck, lint, format and test, or an explicit "none" with the reason.

## 3. Write modes (`fix`, `autofix`)

Before any check, on the files in scope only (on `all` too: the change's files, never the whole tree): the linter's fix mode, then the formatter's write mode, so the formatter has the last word on layout. Skip a file the baseline lists as unformatted: reformatting it would bury the change in layout noise, and its format result is `baseline`. Note every file a write mode changed (`git diff --name-only` before and after).

## 4. Run and classify

Per package in scope, in this order, reading every output:

1. typecheck: zero errors, zero warnings
2. lint: zero errors, zero warnings
3. format check
4. tests, as the Scope table says; `phase` and `slice` add their tasks' `verify:` commands that the tests above do not already run
5. build, where the repo has one, on every scope but `phase`: compiler and type warnings fail; build-tool advisories (bundle size, browserslist age) are notes

A command that cannot run (missing tool, dependency or environment variable) is `fail` with its raw error, never `pass` and never skipped.

Each failure is **new** or **baseline**:

- **With a `baseline:` line** in `todo.md`: baseline when it matches an entry in `<tasks>/baseline.md` and the file holds no more of it than at baseline. Line numbers, durations and absolute paths are ignored; everything else must match:
  - a type error or lint message: file, code or rule, and message
  - a failing test: its full name and its failure, the first line of the assertion or error it reports; the same test failing for another reason is new
  - a format failure: the file
  - a failed build: the first error's file, code and message
  - a command that cannot run: the command and its error
- **Without one** (a run outside the tk workflow, or work started before baselines existed), compare with the code before the change, at `<base>`:
  - a lint message is baseline only when linting that file as it was at `<base>` reports the same rule and message (`git show <base>:<file>` piped to the linter's stdin mode with the file's name, or a temporary worktree at `<base>`). A message on an untouched line can still be the change's own: removing a variable's last use flags its unchanged declaration. When the base version cannot be linted, the message is new.
  - a type error, failing test or failed build is baseline when it is in a file outside the change and involves nothing the change modified (no symbol, type, module or fixture it touched).
  - a command that cannot run is baseline when it also cannot run at `<base>` for the same error.
- Everything else is new.

A check is `pass` with no failure, `fail` with any new failure, `baseline` with baseline failures only, `none` without a command. Only `fail` is red. Baseline failures are reported, never fixed: fixing them is a separate change.

Done when every check in scope has a result.

## 5. Fix (`fix` only)

While a check is `fail`, up to three rounds. A round goes through every failing check, causes first (type errors, then lint, then tests and build, since one type error often explains the rest), applies the write modes to the files it edited, and then re-runs every check in scope, including those that passed before the round: a fix for a test can add a lint error or break the build. A round counts as green only when that whole re-run is.

- **Fix the cause in the code.** Read the raw output, find where the failure comes from, and fix it there, in the structure the code already has.
- **The requirement decides a failing test.** Fix the code. Change a test only when it contradicts the R-id or `accept:` condition it claims to prove, and say which; when that is unclear, stop.
- **Never go green by silencing.** None of these may be added to make a check pass:
  - suppression comments: `eslint-disable…`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `prettier-ignore`, `# type: ignore`, `# noqa`, `//nolint`
  - type escapes: `any`, `as unknown as …`, a cast that hides a mismatch, a non-null `!` the code does not prove
  - weaker tests: `.skip`, `.only`, `xit`, `it.todo`, a deleted test, a loosened or deleted assertion, an expected value changed to match the code's output, snapshots updated without reading what changed
  - weaker tools: an edit to tsconfig, lint, format or test config, CI, package scripts or ignore files that turns a rule off, excludes a file, or raises a threshold
  - deleting the failing code, or a caller's use of it, instead of fixing it

  When one of these is the right fix (a test that must pass a wrong type on purpose), stop and ask; never add it on your own.
- **Stay in scope.** Edit only the files in scope. A fix that needs another file stops the run: called by `tk-implement`, that is its safety gate; run by the human, ask once whether to widen.

A fix that needs a decision, or a fourth round, also stops the run. A stopped run stays red and reports the raw output and what is needed.

When this run changed any file (write modes or fixes) and `plan.md` has `## Verification`, set its `stale: yes`, unless `tk-verify` called it.

Done when every check is `pass`, `baseline` or `none`, or the run stopped with its reason.

## 6. Record and report

The report, on every scope:

```markdown
check: slice · Slice 1 · fix · 2026-10-21 14:02
write modes: eslint --fix → src/export/csv.ts · prettier --write → src/export/csv.ts, src/export/route.ts

| package | check | command | result | notes |
|---|---|---|---|---|
| backend | typecheck | pnpm tsc --noEmit | pass | fixed in round 1 |
| backend | lint | pnpm exec eslint --max-warnings 0 --no-warn-ignored <3 files> | pass | |
| backend | format | pnpm exec prettier --check --ignore-unknown <3 files> | pass | |
| backend | test | pnpm vitest run | baseline | test/legacy.test.ts › parses v1 format, failing at baseline |
| backend | build | — | none | CI does not build |

fixes:
- round 1 · src/export/csv.ts:41 · TS2345 — `row` narrowed with a type guard instead of a cast to `ExportRow`
```

Keep the raw output of every check still `fail` in a fenced block under the table. Then, by scope:

- **`phase` / `slice`**: write, or on a repeat run replace, one line under the heading in `todo.md` (on a `###`, below its `cleanup:` line): `checkpoint: tsc ✓ · eslint ✓ · prettier ✓ · vitest ✓ (baseline 1) · fixed 2 · YYYY-MM-DD HH:MM`, with `✗` on each red check. Report the result, the fixes and the baseline failures to `tk-implement`, and return.
- **`baseline`**: write, or replace, the line under `base:` in `todo.md`: `baseline: clean · YYYY-MM-DD HH:MM`, or `baseline: <n> failing · tsc 0 · eslint 14 · prettier 2 files · vitest 1 · see <tasks>/baseline.md · YYYY-MM-DD HH:MM`, and then write `<tasks>/baseline.md` with one line per entry: package, check, file, code or rule or test name, message (for a test, the first line of its failure; for a build, the first error; for a command that cannot run, the command and its error), count. Return to `tk-implement`.
- **`all`**: return the report to `tk-verify`, which records it.
- **(none)**: write nothing outside the code. Run by the human, end the turn with the report and anything left to fix; called by `tk-implement`, return to it.

## Verification

- [ ] Every command traced to config, scripts, or CI; none guessed; nothing installed.
- [ ] Warnings counted as failures.
- [ ] Write modes and fixes touched only files in scope.
- [ ] No check made green by a suppression comment, a type escape, a weaker test, or a weaker tool config.
- [ ] Every failure classified new or baseline by §4; no baseline failure fixed or counted red.
- [ ] At most three fix rounds; a red result carries its raw output and what is needed.
- [ ] `phase` / `slice` wrote only its `checkpoint:` line and `baseline` only its `baseline:` line and `<tasks>/baseline.md`; `plan.md` changed at most to `stale: yes`; a stage's call returned without ending the turn.
- [ ] No git command that changes state was run.
