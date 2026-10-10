---
name: tk-signoff
description: "Stage [4] of the tk workflow: trace every requirement through plan, code, tests and verification, decide Go / No-Go, and on Go update the intent Outcome and module specs and empty docs/tasks. Use when the user runs it or tk-workflow routes to it."
argument-hint: ""
metadata:
  version: "0.1.0"
---

# tk-signoff

The last look before the human commits. Prove that what was asked is what was built and verified, catch what slipped in, then move the durable knowledge into permanent documents and clear the working files.

## Config

Read `docs/agents/tk-workflow.md` first (specs path, module codes). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

`plan.md` has `## Verification` with `stale: no`, no `fail` row, and a recorded result for every `human` row that backs a MUST requirement. Otherwise point at `tk-verify`.

## 2. Trace

Read the intent, `plan.md`, `todo.md`, and `git diff` (read-only; ask for the base ref if unclear). Build:

| R-id | tasks | files / tests | verification | status |
|---|---|---|---|---|

Then check:

- **Scope creep**: changed files that no task cites. Each is either justified (Slice 0 prefactor, Discovered follow-up explicitly accepted) or a finding.
- **Drift**: places where the implementation differs from the intent or from plan decisions.
- **Leftovers**: Discovered items, human checks still open, SHOULD requirements not delivered.

## 3. Verdict

- **Go**: every MUST traced and verified, no unexplained change.
- **Go with follow-ups**: as Go, plus listed deferred items.
- **No-Go**: a MUST untraced, a drift that changes behaviour, or unexplained scope. Report, leave `docs/tasks/` untouched, point at the stage that fixes it. End the turn.

## 4. On Go: update permanent documents

1. **Intent**: append `## Outcome` (date, verdict, what shipped per R-id, deferred items, Discovered follow-ups). This marks the intent done.
2. **Module specs** under the specs path for every module touched: describe the **current behaviour in timeless language** ("exports are streamed as CSV"), never the change ("added CSV export"). Create a spec file for a new topic; otherwise patch the existing one.
3. **Other existing docs** the change affects (README usage, CHANGELOG if the repo keeps one, an ADR only for a hard-to-reverse decision recorded in the plan). Update what exists; create nothing new beyond specs.
4. **Empty the working files**: replace `plan.md` with `# Plan\n\n_No active work. Run /tk-plan to start._` and `todo.md` with `# Todo\n\n_No active work._`. Their history stays in git.

## 5. Stop

Report the verdict, the trace table, documents updated, and the list of files ready to commit. Suggest follow-ups as new intents. The commit itself is the human's. End the turn.

## Verification

- [ ] Every MUST R-id has tasks, code or tests, and a verification result.
- [ ] Every changed file is cited by a task or explained.
- [ ] Specs read as current state, not change log.
- [ ] `docs/tasks/` emptied only on Go; no git command that changes state was run.
