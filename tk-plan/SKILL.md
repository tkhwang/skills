---
name: tk-plan
description: "Stage [1] of the tk workflow: turn an intent into docs/tasks/plan.md and todo.md as vertical slices, each Backend then Frontend, with an R-id coverage matrix and no unresolved decisions. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[MODULE###-slug]"
metadata:
  version: "0.1.0"
---

# tk-plan

Read the intent and the code, write the plan and task list, resolve the decisions that matter with `tk-grill`, and stop for approval. Planning is read-only on code.

## Config

Read `docs/agents/tk-workflow.md` first (docs paths, packages, verify commands, module code locations). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

- **Intent**: the argument, or the single intent without `## Outcome`; several → ask. If its `## Open questions` is non-empty, offer to run `tk-grill` on it first; the human may decline.
- **Approval**: ask "이 intent 로 계획을 세울까요?" and wait for an explicit yes.
- **Active plan**: if `plan.md` is filled and `todo.md` has unchecked boxes for a *different* intent, **stop and ask**. Another session may be mid-build. Never overwrite it on your own.

Done when the intent is approved and `docs/tasks/` is free.

## 2. Read

The intent (every R-id), the module specs under the specs path for every module touched, the code locations from the config, and the verify commands (config table, else `package.json` scripts and CI workflows).

## 3. Draft slices

- Map dependencies first; if a prefactor would make the change easy, it becomes **Slice 0**.
- Cut the work into **vertical slices**: each delivers one demoable behaviour end to end. Inside a slice, order is `### Backend` then `### Frontend`; drop a sub-section the slice does not need. Shared types or API contracts are the first Backend task of the slice that introduces them.
- Each task: one sentence, `covers: R…`, files likely touched, the focused verify command, acceptance criterion. A task touching more than ~5 files or two subsystems splits.
- A wide mechanical refactor (rename across the codebase) is the exception: sequence it expand → migrate → contract instead of forcing a vertical slice.

## 4. Resolve decisions

Invoke `tk-grill` on `plan.md` (plan profile). Its first question is slice granularity and order; then contracts, data, authz, async, conflicts with specs, and every new file or folder path. A plan with an open decision is not ready.

Done when `tk-grill` reports the frontier empty.

## 5. Write

`plan.md` and `todo.md` from the templates. Fill the coverage matrix: every R-id maps to at least one task, every task cites at least one R-id (or Slice 0 prefactor).

## 6. Stop

Summarize: slices, task count, decisions made, risks, verify commands. Print the next command (`/tk-implement` or `다음`). End the turn.

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
- [ ] T1.1 <task> · covers: R1 · files: … · verify: `<cmd>` · accept: <condition>
### Frontend
- [ ] T1.2 <task> · covers: R1 · files: … · verify: `<cmd>` · accept: <condition>

## Slice 2: <behaviour>
### Backend
- [ ] …
```

## Verification

- [ ] No code was written.
- [ ] Every R-id appears in Coverage; every task cites an R-id.
- [ ] Decision Log shows no open decision; new paths are named.
- [ ] Turn ended; `tk-implement` was not started.
