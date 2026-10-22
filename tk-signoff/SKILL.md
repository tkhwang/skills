---
name: tk-signoff
description: "Stage [4] of the tk workflow: trace every requirement through plan, code, tests and verification, decide Go / No-Go, and on Go append the intent Outcome, update module specs, move the intent to the intents folder under its ID and empty docs/tasks without asking; the human commits after signoff. Use when the user runs it or tk-workflow routes to it."
metadata:
  version: "0.4.0"
---

# tk-signoff

The last look before the human commits. Prove that what was asked is what was built and verified, catch what slipped in, then move the durable knowledge into permanent documents and empty `<tasks>`. The human commits after signoff: code, intent, specs and the emptied working files land in one commit.

## Config

Read `docs/agents/tk-workflow.md` first (specs path, intents path, tasks path as `<tasks>`, default `docs/tasks/`, module codes). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

`plan.md` has `## Verification` with `stale: no`, a `### Audit` section, no row whose result is `fail` in any of its tables (commands, behaviour checks, audit), and a recorded result for every `human` row that backs a MUST requirement. A record without `### Audit` predates audits or skipped them. Otherwise point at `tk-verify`.

## 2. Trace

Read the intent (`<tasks>/intent.md`; a legacy intent under the intents path when that file does not exist), `plan.md`, `todo.md`, and the change as `tk-verify` §1 defines it (per repository, `git diff` against its `base:` entry in `todo.md` plus untracked files; read-only). Build:

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

## 4. On Go: update permanent documents, empty `<tasks>`

The commit comes after signoff, so this step never asks whether to commit first or whether to empty: Go is the decision.

1. **Intent**: append `## Outcome` (date, verdict, what shipped per R-id, deferred items, follow-ups: Discovered items and the `follow-up intent:` lines under Non-goals, and the verification in brief: the `## Verification` run line, the `### Audit` summary line, the peers who audited, and every `note`). This marks the intent done, and keeps the verification evidence in a permanent document.
2. **Module specs** under the specs path for every module touched: describe the **current behaviour in timeless language** ("exports are streamed as CSV"), never the change ("added CSV export"). Create a spec file for a new topic; otherwise patch the existing one.
3. **Other existing docs** the change affects (README usage, CHANGELOG if the repo keeps one, an ADR only for a hard-to-reverse decision recorded in the plan). Update what exists; create nothing new beyond specs.
4. **Move the intent** out of `<tasks>` under its ID, by `tk-intent`'s *Path and filename* rule: `<intents dir>/<MODULE><NNN>-<slug>.md`, `id` and `slug` added to the frontmatter, `# <ID> · <title>` as the H1, moved with `mv`, nothing left at `<tasks>/intent.md`. Ask only if `module:` is empty. A legacy intent already under the intents path stays where it is.
5. **Empty the rest of `<tasks>`**: replace `plan.md` with `# Plan\n\n_No active work. Run /tk-intent to start._` and `todo.md` with `# Todo\n\n_No active work._`, and delete `<tasks>/baseline.md` and the contents of `<tasks>/reviews/` and `<tasks>/debates/`. What `plan.md` and `todo.md` held stays in git only where the human committed it earlier; the Outcome carries the verification and audit summary.

## 5. Stop

Report the verdict, the trace table, the intent's new path, documents updated, and the files to commit now as one commit: the code, the intent, the specs and the emptied `<tasks>`. Suggest follow-ups as new intents. The commit itself is the human's, after signoff. End the turn.

## Verification

- [ ] Every MUST R-id has tasks, code or tests, and a verification result.
- [ ] Every changed file is cited by a task or explained.
- [ ] Specs read as current state, not change log.
- [ ] The Outcome carries the verification and audit summary.
- [ ] On Go the intent moved to the intents path under its ID and `<tasks>` was emptied, without asking about commits; on No-Go `<tasks>` is untouched.
- [ ] No git command that changes state was run; the commit is left to the human, after signoff.
