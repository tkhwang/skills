---
name: tk-signoff
description: "Stage [4] of the tk workflow: trace every requirement through plan, code, tests and verification, decide Go / No-Go, and on Go update the intent Outcome and module specs and empty docs/tasks. Use when the user runs it or tk-workflow routes to it."
metadata:
  version: "0.3.1"
---

# tk-signoff

The last look before the human commits. Prove that what was asked is what was built and verified, catch what slipped in, then move the durable knowledge into permanent documents and clear the working files.

## Config

Read `docs/agents/tk-workflow.md` first (specs path, tasks path as `<tasks>`, default `docs/tasks/`, module codes). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

`plan.md` has `## Verification` with `stale: no`, a `### Audit` section, no row whose result is `fail` in any of its tables (commands, behaviour checks, audit), and a recorded result for every `human` row that backs a MUST requirement. A record without `### Audit` predates audits or skipped them. Otherwise point at `tk-verify`.

## 2. Trace

Read the intent, `plan.md`, `todo.md`, and the change as `tk-verify` §1 defines it (per repository, `git diff` against its `base:` entry in `todo.md` plus untracked files; read-only). Build:

| R-id | tasks | files / tests | verification | status |
|---|---|---|---|---|

Then check:

- **Scope creep**: changed files that no task cites. Each is either justified (Slice 0 prefactor, Discovered follow-up explicitly accepted) or a finding.
- **Drift**: places where the implementation differs from the intent or from plan decisions.
- **Audit**: the `### Audit` ledger has a row for every task in `todo.md`, every R-id in the intent, and every Quality bar line; every task is `done`, every R-id `complete`, every Quality bar line `met`, and no test `hollow`. Compare the ledger with the files, not with its own summary line. `Quality bar: none` is reported as such.
- **Leftovers**: Discovered items, human checks still open, SHOULD requirements not delivered, review findings triaged `deferred` and audit findings marked `discovered` under `<tasks>/reviews/`.

## 3. Verdict

- **Go**: every MUST traced and verified, no unexplained change.
- **Go with follow-ups**: as Go, plus listed deferred items.
- **No-Go**: a MUST untraced, a drift that changes behaviour, unexplained scope, or an audit ledger with a missing item or a result short of `done` / `complete` / `met` / not `hollow`. Report, leave `<tasks>` untouched, point at the stage that fixes it. End the turn.

## 4. On Go: update permanent documents

1. **Intent**: append `## Outcome` (date, verdict, what shipped per R-id, deferred items, Discovered follow-ups, and the verification in brief: the `## Verification` run line, the `### Audit` summary line, the peers who audited, and every `note`). This marks the intent done, and keeps the verification evidence in a permanent document.
2. **Module specs** under the specs path for every module touched: describe the **current behaviour in timeless language** ("exports are streamed as CSV"), never the change ("added CSV export"). Create a spec file for a new topic; otherwise patch the existing one.
3. **Other existing docs** the change affects (README usage, CHANGELOG if the repo keeps one, an ADR only for a hard-to-reverse decision recorded in the plan). Update what exists; create nothing new beyond specs.
4. **Empty the working files**, without losing them. First run `git status --porcelain` on the tasks path: anything uncommitted or untracked there is not in git yet, since the agent never commits. If so, list it and ask whether to empty now (the Outcome keeps the verification summary) or to stop so the human commits the working files first; wait for the answer. Then replace `plan.md` with `# Plan\n\n_No active work. Run /tk-plan to start._` and `todo.md` with `# Todo\n\n_No active work._`, and delete `<tasks>/baseline.md` and the contents of `<tasks>/reviews/` and `<tasks>/debates/`. Committed history is the archive.

## 5. Stop

Report the verdict, the trace table, documents updated, and the list of files ready to commit. Suggest follow-ups as new intents. The commit itself is the human's. End the turn.

## Verification

- [ ] Every MUST R-id has tasks, code or tests, and a verification result.
- [ ] Every changed file is cited by a task or explained.
- [ ] Specs read as current state, not change log.
- [ ] The Outcome carries the verification and audit summary.
- [ ] `<tasks>` emptied only on Go, and only after the human chose to when it held uncommitted files; no git command that changes state was run.
