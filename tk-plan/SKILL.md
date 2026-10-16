---
name: tk-plan
description: "Stage [1] of the tk workflow: turn an intent into docs/tasks/plan.md and todo.md as vertical slices, each Backend then Frontend, with an R-id coverage matrix and no unresolved decisions. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[MODULE###-slug]"
metadata:
  version: "0.3.1"
---

# tk-plan

Read the intent and the code, write the plan and task list, resolve the decisions that matter with `tk-grill`, and stop for approval. Planning is read-only on code.

## Config

Read `docs/agents/tk-workflow.md` first (docs paths, packages, verify commands, module code locations). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

- **Intent**: the argument, or the single intent without `## Outcome` outside `archived/`; several → ask. If its `## Open questions` is non-empty, offer to run `tk-grill` on it first; the human may decline.
- **Approval**: entered through the driver's `다음` / `next`, that keyword is the approval. Invoked directly, ask "이 intent 로 계획을 세울까요?" and wait for an explicit yes.
- **Active plan**: if `plan.md` is filled for a *different* intent, in any state (tasks open, all checked, verified, awaiting signoff), **stop and ask**. Only `tk-signoff` clears the working files; until then another session may be mid-build or its verification record is still needed. Never overwrite them on your own.
- **Same intent, plan already filled** (re-planning): treat it as a revision. Keep `## Decision Log` and `## Discovered`, redraft the sections the request names, and re-run step 4 only for decisions the redraft reopened. If any box in `todo.md` is checked, stop and ask; implemented work is not re-planned silently.

Done when the intent is approved and `docs/tasks/` is free.

## 2. Read

The intent (every R-id), the module specs under the specs path for every module touched, the code locations from the config, and the verify commands (config table, else `package.json` scripts and CI workflows).

## 3. Draft slices and write the draft

- Map dependencies first; if a prefactor would make the change easy, it becomes **Slice 0**.
- Cut the work into **vertical slices**: each delivers one demoable behaviour end to end. Inside a slice, order is `### Backend` then `### Frontend`; drop a sub-section the slice does not need. Shared types or API contracts are the first Backend task of the slice that introduces them.
- Each task: one sentence, `covers: R…`, files likely touched, the focused verify command, acceptance criterion. A task touching more than ~5 files or two subsystems splits. A task that adds or changes a migration, schema, or seed also carries `db: yes`, and only such a task: `tk-implement` stops after its sub-phase for the human to look.
- A wide mechanical refactor (rename across the codebase) is the exception: sequence it expand → migrate → contract instead of forcing a vertical slice.
- **Write the draft now**: `plan.md` and `todo.md` from the templates, with the slices, proposed paths, and candidate decisions filled in and open items listed under `## Decision Log` as `open:`. `tk-grill` needs a file to read and patch.

Done when both files exist with the draft content.

## 4. Resolve decisions

Invoke `tk-grill` on `plan.md` (plan profile). Its first question is slice granularity and order; then contracts, data, authz, async, conflicts with specs, and every new file or folder path. A plan with an open decision is not ready.

Done when `tk-grill` reports the frontier empty.

## 5. Finalize

Apply the resolved decisions to both files: adjust slices, tasks, and paths; fill the coverage matrix so every R-id maps to at least one task and every task cites at least one R-id (or Slice 0 prefactor); leave no `open:` entry in Decision Log.

## 6. Stop

Summarize: slices, task count, decisions made, risks, verify commands, and the sub-phases where `tk-implement` will stop for a database change (`db: yes`). Print the next command (`/tk-implement` or `다음`; `리뷰` to have peers read the plan first, `토론 Q<n>` to contest a decision). End the turn.

## plan.md template

```markdown
---
intent: AGENT001-tenant-export
---
# Plan · AGENT001 Tenant data export

## Summary
## Architecture decisions
- <decision> — <rationale>
## Scope
- modules / packages touched
- new files (exact paths)
## Slices
1. Slice 1 — <behaviour delivered>
2. Slice 2 — …
## Verification plan
| package | typecheck | lint | format | test |
|---|---|---|---|---|
Behaviour checks: <how each R-id is observed>
## Risks
| risk | impact | mitigation |
|---|---|---|
## Coverage
| R-id | slice / task | notes |
|---|---|---|
## Decision Log
## Discovered
```

`## Verification` is appended by `tk-verify`.

## todo.md template

```markdown
# Todo · AGENT001-tenant-export

## Slice 1: <behaviour>
### Backend
- [ ] T1.1 <task> · covers: R1 · files: … · db: yes · verify: `<cmd>` · accept: <condition>
- [ ] T1.2 <task> · covers: R1 · files: … · verify: `<cmd>` · accept: <condition>
### Frontend
- [ ] T1.3 <task> · covers: R1 · files: … · verify: `<cmd>` · accept: <condition>

## Slice 2: <behaviour>
### Backend
- [ ] …
```

## Verification

- [ ] No code was written.
- [ ] Every R-id appears in Coverage; every task cites an R-id.
- [ ] Every task that changes a migration, schema, or seed carries `db: yes`; no other task does.
- [ ] Decision Log shows no open decision; new paths are named.
- [ ] Turn ended; `tk-implement` was not started.
