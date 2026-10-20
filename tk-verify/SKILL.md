---
name: tk-verify
description: "Stage [3] of the tk workflow: run the repo's typecheck, lint (warnings fail), format check, tests and build through tk-check in report mode, plus the plan's behaviour checks, then audit the work itself: every task and R-id in the code, what each test really asserts, the plan's Quality bar, and leftover mess. Named peers (claude, codex, grok) audit independently and the orchestrator confirms their findings. Results are recorded per R-id in plan.md. With slice it is the audit tk-implement calls at every slice boundary, right after tk-check slice: that slice's behaviour checks and audit, recorded in todo.md. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[fix] [claude | codex | grok …] | slice"
metadata:
  version: "0.5.0"
---

# tk-verify

Measure, then report; never fix code. A checked box, a "done" in chat, and a green test run are claims, not evidence: this stage opens the code and the tests and checks each claim itself. Commands come from the repo and warnings count as failures; `tk-check` runs them in `report` mode (`autofix` under `fix`), so the stage and every checkpoint run the same commands. Without a scope argument this is the stage: every package, the full suite, a full audit, optional peer audits, results in `plan.md` under `## Verification` for `tk-signoff`. With `slice` it is the audit `tk-implement` calls at every slice boundary, right after `tk-check slice` has run the commands: that slice's behaviour checks and audit, recorded under its heading in `todo.md`. The sub-phase checkpoint is `tk-check phase`; `phase` is not a scope here.

## Scope

| Argument | Runs | Records | Called by |
|---|---|---|---|
| `slice` | the plan's behaviour checks for the R-ids that slice covers where they can run without a human, plus the §5 audit scoped to the slice; the commands already ran in `tk-check slice` | `audit:` line under the `##` heading, below `tk-check`'s `checkpoint:` line, then one indented line per failing finding | `tk-implement` at every slice boundary, after `tk-check slice` |
| (none) | everything below, all packages, full audit | `plan.md` `## Verification` | the human or the driver after the last task |

**Peers.** Peer names (`/tk-verify codex grok`, `/tk-verify fix claude`) add an independent audit by each named agent (§3). Without names the current agent audits alone. Peers run on a full run only: with `slice` the names are rejected with a one-line reason, since checkpoints run many times inside one build.

**Scoped runs** never touch `plan.md` and never change the `stale:` flag; findings that belong in `## Discovered` are reported to `tk-implement`, which records them. A scoped run is red when a behaviour check or an audit finding is `fail` (§6), green otherwise. Pass or fail, it reports and returns to `tk-implement` in the same turn without ending it; fixing and deciding where to stop are `tk-implement`'s job. A repeat run on a heading that already carries an `audit:` line (the fix loop) replaces that line and its finding lines, and re-audits only the findings that failed plus the files changed since; the full slice audit runs once per slice. §8 applies to full runs only.

## Config

Read `docs/agents/tk-workflow.md` first: the packages, the tasks path (`<tasks>` below, default `docs/tasks/`), and `## Peers` for peer names and command overrides. If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

Full scope: every box in `todo.md` is checked; otherwise list the unchecked tasks and point at `tk-implement`. `slice`: every box of that slice is checked, and its `checkpoint:` line from `tk-check slice` has no `✗`; otherwise point at `tk-check slice`. A checked box means the work is ready to audit; §5 decides whether it is done.

**The change** under audit is collected per repository in scope: every distinct git repository among the config's package paths and the docs home (`git -C <path> rev-parse --show-toplevel`). In each one it is `git diff <base>` plus its untracked files (`git ls-files --others --exclude-standard`). `<base>` is that repository's entry on the `base:` line `tk-implement` writes in `todo.md` when work starts: `base: <sha>` for a single repository, `base: <repo path>@<sha> · <repo path>@<sha>` for several, paths relative to the docs home. A repository without an entry falls back to the merge-base of its `HEAD` and its default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`); ask once if that does not resolve. `tk-implement`, `tk-signoff` and `tk-multi-review` use this same definition. A scoped run narrows the change to the files its tasks list and the untracked files beside them.

## 2. Commands

`tk-check` discovers them (its §2: the config's Verify table, the plan's Verification plan, package scripts, CI) and runs them; this stage keeps no command list of its own and runs none of those commands itself. The behaviour checks in §4 come from the plan's Verification plan.

## 3. Launch peer audits (full run with peer names)

Peers take the longest, so they launch early and work while §4 and §5 proceed. With `fix`, they launch right after `tk-check` returns in §4, so that every peer reads the autofixed tree the audit judges. Skip this section when no peer is named.

- **Who**: each name, matched against `## Peers` names first (any role; naming a peer is the choice), then kinds (`claude`, `codex`, `grok`). A kind not on `PATH` is skipped with a one-line note. Naming the orchestrator's own kind is allowed and useful: a fresh headless process carries none of the context of the session that wrote the code. Peers add to the orchestrator's own audit; they never replace it.
- **Prompt**: self-contained, since the peer cannot see this conversation, written to `<tasks>/reviews/audit-<peer>.prompt.md`. Name only paths that exist.
- **Launch**: commands, override rules and placement exactly as `tk-multi-review` §4 (default command per kind, a `command` override only if it keeps the kind's read-only flag, a sibling pane per peer inside herdr, directly elsewhere), all peers concurrently, 10-minute timeout each. This section only launches; §6 waits for the processes to exit. Result: `<tasks>/reviews/audit-<peer>.md`, with a header prepended once the process exits: `reviewer: <peer> · stage: audit · run: YYYY-MM-DD HH:MM · artifact: git diff <base> · command: default | override`.

```markdown
You are auditing finished work, read-only, inside the workspace at <abs docs home path>.
Do not edit any file. Do not run tests or builds; the orchestrator runs every command.
Answer in <document language>.

Treat every claim as unproven: checked boxes and `evidence:` lines in todo.md, "done"
anywhere, and passing tests are what you are checking, not facts. Judge against the
intent's R-ids, the tasks' accept: conditions and the plan's Quality bar; anything
else is at most a nit.

Read: the intent <path> (every R-id), <tasks>/plan.md (Design direction, Quality bar,
Verification plan), <tasks>/todo.md (tasks and their accept: conditions), and the change,
per repository: <repo path> · `git -C <repo path> diff <base>` · untracked: <list>.
Read every file the change touches, and its tests.

Audit:
1. Requirements: for every task, does the code meet its accept: condition? For every R-id,
   is the behaviour complete and reachable end to end, including the error paths and
   edge cases the Quality bar names?
2. Tests: for every test cited as evidence or changed in the diff, would it fail if the
   behaviour it claims were removed or broken? Look for expected values hardcoded or
   copied from the output, the unit under test mocked, skipped or focused tests, missing
   or trivial assertions, swallowed errors, assertions loosened in the diff.
3. Quality bar: each line, met or not, and the place that breaks it.
4. Hygiene in what the change added: debug output, commented-out code, code the change
   made dead, scratch files, TODO/FIXME that plan.md does not name, duplication, names
   that drifted from the plan.

Report in exactly this format. If you find nothing, the only entry under Findings is `- none`.
## Findings
- [requirement|test|quality|hygiene] [blocker|should|nit] <R-id or task id or —> · <file:line> — <claim> · evidence: <what you read> · fix: <one sentence>
## Verdict
<sound | gaps> — <one sentence>
```

Done when every named peer is launched or skipped with a note.

## 4. Run

1. **Commands** (full run): invoke `tk-check all report` with the Skill tool, or `tk-check all autofix` under `fix`. It runs, per package, typecheck, lint, format check, the full test suite once and the build where the repo has one, warnings as failures, and returns its table. Each check is `pass`, `fail`, `none`, or `baseline`: failing only on what already failed before the work started, as the `baseline:` line in `todo.md` records. `baseline` does not block; its entries go to `## Discovered` (§6). On `slice` the commands already ran in `tk-check slice`; skip this step.
2. **Behaviour checks** from the plan's Verification plan (on `slice`, those for its R-ids): run what can be run (CLI, HTTP, scripts); list for the human what needs a browser or a device, with exact steps and the R-id each proves.

`fix` is full scope only (`slice fix` is rejected with a one-line reason, since scoped runs never change code): it lets `tk-check` apply the formatter's and the linter's write modes to the change's files before it measures, and nothing else. Type errors, failing tests and audit findings are never fixed here; `tk-check` at its default `fix` level or `tk-implement` fixes them.

## 5. Audit

Read as a reviewer who did not write this code: open the files themselves, not the `evidence:` lines in `todo.md` or the memory of writing them.

- **Full run**: every task, R-id, test and Quality bar line of the work.
- **`slice`**: the slice's tasks, the part of each R-id this slice delivers, the tests in its files, and the Quality bar lines that apply to them. What the plan assigns to a later slice is `pending`, never a failure; whether an R-id is complete across slices is judged on the full run.

1. **Requirements, one by one.** For every task, open the files it lists and confirm its `accept:` condition holds in the code: `done`, `partial` or `missing`, with `file:line`. For every R-id, confirm all its tasks are done and the behaviour is reachable end to end: registered, exported, called, rendered, not only written. That includes the error paths and edge cases the Quality bar names for it; happy path only is `partial`. Result: `complete`, `partial` or `missing` (on a slice: for the part this slice delivers). Re-run any task's `verify:` command that the full suite does not already cover, and compare the output with its `evidence:` line.
2. **Tests, inside not outside.** Read every test cited as evidence and every test added or changed in the change, and ask: would it fail if the behaviour it claims to prove were removed or inverted? Mark it `sound`, `weak` (proves part of the claim) or `hollow` (proves nothing). Signs of hollow:
   - expected values hardcoded or copied from the implementation's own output instead of derived from the requirement
   - the unit under test mocked or stubbed, or assertions only on mocks being called
   - skipped, focused or placeholder tests (`.skip`, `.only`, `xit`, `it.todo`, `@pytest.mark.skip`, …)
   - no assertion, or only `toBeDefined` / `not.toThrow` style assertions where the requirement specifies a value
   - errors swallowed by `try` / `catch`, or a test that passes on any outcome
   - snapshots accepted without reading their content
   - assertions loosened or deleted in the change

   On a full run, if the repo configures a mutation-testing tool, run it on the changed files and report surviving mutants. Never introduce one here.
3. **Quality bar.** Each line of `plan.md` `## Quality bar` in scope: `met` or `not met`, with the place that breaks it. A plan without a Quality bar skips this step and the record says `Quality bar: none`; no bar is invented here.
4. **Hygiene**, over what the change added or modified (diff hunks and untracked files). Debt that was there before the change is `discovered`, not a failure.
   - mechanical leftovers: debug output, commented-out code, code the change made dead, scratch or temporary files, `TODO` / `FIXME` that `plan.md` does not track (tracked means a task or a `## Discovered` entry names its `file:line`)
   - judgement items: duplication between tasks, names that drifted from the plan or specs, comments that narrate the change

   Confirm every `###` sub-phase in scope carries a `cleanup:` line, and on a full run that `todo.md` ends with the `cleanup (final):` line. Measure only; nothing is removed here.

Write each finding as: category, R-id or task id, `file:line`, what is wrong, evidence.

Done when every item in scope has a result.

## 6. Consolidate

Wait for every peer launched in §3 to exit. A peer has answered only when its file holds a `## Findings` section whose every entry follows the prompt's format (or is the single entry `- none`) and a `## Verdict` line that starts with `sound` or `gaps`. Anything else (empty, timed out, an error message, unstructured text, a heading with nothing valid under it) is `no answer`: the peer is not counted as having audited, though anything concrete in its text may still be checked as a lead. Collect the findings from §5 and from every answering peer, merge duplicates, and note who found each.

A peer finding is a lead, not a result: check each one in the repo before it counts. Peers agreeing is stronger evidence, not a verdict; nothing is decided by vote. Give every finding one disposition, and append the peer's list as `## Triage` to its result file (`- <finding> → fail | note | discovered | rejected: <why>`):

- **fail**: confirmed, and it leaves a task's `accept:` unmet, an R-id (on a slice: this slice's part of it) incomplete, or a Quality bar line not met; or it is a `hollow` test, a `weak` test that is the only test evidence for a MUST R-id, or a mechanical hygiene leftover the change introduced.
- **note**: confirmed and in scope, but none of the above: a `weak` test beside sound evidence, a judgement hygiene item that no Quality bar line covers. Listed; does not block.
- **discovered**: confirmed, but outside what the plan asked: a structure the plan did not choose, debt that predates the change (a `baseline` command result included), mess in files the change did not touch. Full run: record it in `plan.md` `## Discovered` as `NOTICED, NOT TOUCHED`. Scoped run: report it to `tk-implement`.
- **rejected**: the repo contradicts it. Say why in one sentence; rejecting a peer's `blocker` needs `file:line` evidence.

Only `fail` blocks. A named peer with `no answer` is listed in the record and named again in §8; the audit stands on the rest, and the human decides whether to re-run `/tk-verify <peer>`.

Done when no finding lacks a disposition.

## 7. Record

**Scoped run**: write, or on a repeat run replace, the `audit:` line under the `##` heading in `todo.md`, below `tk-check`'s `checkpoint:` line: `audit: ✓ · <behaviour check> ✓ · … · YYYY-MM-DD HH:MM`, or `audit: ✗ (n) · …`, followed on failure by one indented line per `fail` finding (`- audit: <file:line> — <what is wrong>`) so `tk-implement` can fix them. Report pass or fail, plus any `discovered` items, and return to `tk-implement`; skip §8 and do not end the turn.

**Full run**: append or replace `## Verification` in `plan.md`. The `### Audit` ledger has one row for every task in `todo.md`, every R-id in the intent, and every Quality bar line, so that nothing is counted without being listed:

```markdown
## Verification
run: 2026-10-10 14:02 · fix: no · stale: no · audit: self, codex, grok (no answer)

| package | check | command | result | notes |
|---|---|---|---|---|
| backend | typecheck | pnpm tsc --noEmit | pass | |
| backend | lint | pnpm eslint . --max-warnings 0 | fail | 2 warnings in src/export/csv.ts |
| backend | test | pnpm vitest run | baseline | test/legacy.test.ts › parses v1 format, failing before the work (Discovered) |

| R-id | behaviour check | result | evidence |
|---|---|---|---|
| R1 | 403 on foreign tenant id | pass | curl … → 403 |
| R3 | async over 100k rows | human | steps below |

### Audit
tasks 8/9 done · R-ids 3/4 complete · tests 12 sound, 1 weak, 1 hollow · Quality bar 5/6 met · cleanup lines 4/4 + final

| item | result | where | tests |
|---|---|---|---|
| T1.1 | done | src/export/route.ts:12 | |
| T1.3 | partial | src/export/csv.ts:88 | |
| R1 | complete | src/export/route.ts:12 | test/export.test.ts:20 sound · test/export.test.ts:41 hollow |
| R2 | partial | src/export/csv.ts:88 | test/export.test.ts:60 sound |
| QB structure | met | src/export/ | |
| QB behaviour R2 | not met | src/export/csv.ts:88 | |

| # | kind | R-id / task | where | finding | found by | result |
|---|---|---|---|---|---|---|
| A1 | requirement | R2 / T1.3 | src/export/csv.ts:88 | empty tenant returns 500; Quality bar says 404 | self, codex | fail |
| A2 | test | R1 | test/export.test.ts:41 | expected rows copied from output; passes with the tenant filter removed | codex | fail |
| A3 | hygiene | T1.2 | src/export/csv.ts:12 | `console.log` added | self | fail |
| A4 | test | R1 | test/export.test.ts:75 | asserts row count only; row content is covered by :20 | self | note |
| A5 | quality | — | src/report/ | report module, which this plan does not touch, uses the same old pattern | codex | discovered |
| A6 | test | R3 | test/async.test.ts:10 | "queue not awaited" | codex | rejected: line 14 awaits `drain()` |

### Human checks
1. … (proves R3)
```

The command rows are `tk-check`'s report as it returned it. Keep the raw output of any failing command in a fenced block under its table. Peer prompts and answers stay under `<tasks>/reviews/audit-*`.

## 8. Stop (full run)

- Any `fail`, from a command, a behaviour check or the audit → list them with the R-ids affected and point at `tk-implement`; its fix mode turns each failing row into a task. When only commands failed, `/tk-check` fixes them directly; then verify again. End the turn.
- A `human` row that is the acceptance evidence for a **MUST** requirement needs a result before signoff: print the steps, ask the human to run them and report, and record `pass` / `fail` with their evidence. Until then the work is **awaiting human verification**; say so and end the turn without pointing at signoff.
- No `fail` anywhere (`note`, `discovered` and `rejected` do not block; a `human` row may stay open only for a SHOULD, and is listed as such) → print the audit summary line, the peers who took part, any named peer with no answer (with `/tk-verify <peer>` to retry), and the next command (`/tk-signoff` or `다음`). End the turn.

`tk-implement` sets `stale: yes` on this section when code changes after the run; a stale section means verify again, audit included.

## Verification

- [ ] Every command ran through `tk-check` (`report`, or `autofix` under `fix`), none here; warnings reported as failures.
- [ ] `baseline` results did not block and went to Discovered.
- [ ] Every task and R-id was checked in the code itself, not taken from checked boxes or `evidence:` lines; the full-run ledger lists every one of them.
- [ ] Every evidence test was read; `hollow` tests recorded as `fail`.
- [ ] A slice audit failed nothing that the plan assigns to a later slice.
- [ ] Peers ran only when named, only on a full run, read-only, on the tree the audit judged; a peer counted as answering only with well-formed Findings and Verdict; every peer finding was checked in the repo before it counted, none by vote.
- [ ] Results recorded in `plan.md`, not only in chat.
- [ ] No code edited beyond formatter and linter autofix under `fix`.
- [ ] A `slice` run wrote only its `audit:` line (and its failing finding lines) in `todo.md`, nothing in `plan.md`, and returned to `tk-implement` without ending the turn.
