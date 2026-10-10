---
name: tk-implement
description: "Stage [2] of the tk workflow: implement docs/tasks/todo.md task by task, stopping at every Backend/Frontend sub-phase boundary (or running to the end with auto), checking boxes with evidence. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[auto]"
metadata:
  version: "0.1.0"
---

# tk-implement

Work the task list in order. Verify each task with its focused command, check it off with evidence, and pause at sub-phase boundaries so the human can look. The agent changes code and `docs/tasks/`; it never changes git state.

## Config

Read `docs/agents/tk-workflow.md` first (packages and their paths, verify commands). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## 1. Preconditions

- `plan.md` is filled and `todo.md` has tasks.
- **Fix mode**: if every box is already checked and `plan.md` `## Verification` has failing rows, add a `## Fixes` section to `todo.md` with one task per failing row (`covers:` the affected R-ids, `verify:` the failing command) and work those; the loop below is unchanged.
- `plan.md` Decision Log shows no open decision; otherwise stop and point at `tk-grill`.
- If no box is checked yet, ask "이 plan 으로 구현을 시작할까요?" and wait for an explicit yes.
- Run `git status --porcelain`. Report uncommitted changes outside `docs/` in one line and ask whether to proceed. Inform only; the human owns commits.

Done when approval is explicit and the starting point is known.

## 2. Mode

| Mode | Stops |
|---|---|
| default | after every `###` sub-phase (Backend or Frontend of a slice): report, wait for `다음` |
| `auto` | only at safety gates below |

`auto` is selected by the argument or by the driver keyword. Both modes run the same per-task loop.

## 3. Task loop

For the next unchecked task:

1. **Frame**: restate the task, its R-ids, and the decisions that constrain it.
2. **Test first when it locks behaviour**: write or extend a test and watch it fail for the right reason. Pure wiring or config: no ceremonial test.
3. **Smallest change** inside the task's files. Simplest thing that works; three similar lines beat a premature abstraction.
4. **Verify**: the task's focused command, plus typecheck of the touched package. Read the output. Full suites, lint and format belong to `tk-verify`; run a command again only after code changed.
5. **Check off**: `- [x] T1.1 … · evidence: <command> → <result>` in `todo.md`, at the moment it passes.
6. **Mark verification stale**: on the first code change after `plan.md` has a `## Verification` section, set its `stale: yes`. `tk-verify` must run again before signoff.

A task is done only on observed passing output, or on evidence the human pasted.

## 4. Sub-phase boundary (default mode)

When the last task of a `###` section is checked: report what changed, the evidence, remaining risk, and the next sub-phase. End the turn. Resume on `다음`.

## 5. Scope discipline

Anything the plan did not ask for goes to `plan.md` `## Discovered` as `NOTICED, NOT TOUCHED: <what> · <where> · <suggested follow-up>`. Then: a small in-scope fix continues; a change that widens scope or needs a decision stops (safety gate).

## Safety gates (stop in any mode)

- an open decision surfaces
- the change would exceed the plan's scope
- destructive or irreversible action (data loss, schema drop, force operations)
- external or production impact, credentials
- a verification fails and the fix needs a human decision

## 6. Done

When every box is checked: summary of tasks, evidence, files changed, Discovered items. Print the next command (`/tk-verify` or `다음`). End the turn.

## Verification

- [ ] Each task checked only after reading passing output.
- [ ] No `git commit`, `push`, `stash`, `checkout`, `reset` executed.
- [ ] Default mode stopped at every `###` boundary.
- [ ] Out-of-plan findings recorded under Discovered, not fixed silently.
- [ ] `## Verification` marked `stale: yes` if it existed before this run's code changes.
