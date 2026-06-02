---
name: plan-execute
description: Use when you have an approved plan whose pre-implementation decisions are already resolved and you want to implement it. Runs the plan's steps in order in one of two modes — auto (run to completion in one pass) or checkpoint (stop after each major step for human confirmation) — and verifies build, type, lint, and test results at every step before moving on. Pairs with plan-decision-grill, which resolves the plan's decision gates first.
metadata:
  version: "1.0.0"
---

# Plan Execute

Take an approved plan and implement it step by step. Verify each step (build / types / lint / tests) before moving to the next. Two modes control how often execution pauses for the human.

## Conversation language

All reporting, questions, and confirmations to the user are written in **Korean**, regardless of this document's language. The plan file and code follow the project's existing conventions.

## Preconditions — read before executing

1. **Locate the plan.** Use the file the user names. If none is named, look in `./plans/`, then `docs/plans/`. If still ambiguous, ask which plan to execute.
2. **Check the decision gates.** Read the plan's decision section (`## Decision Gates`, `## 결정 필요 사항`, or equivalent).
   - If **any** decision gate is unresolved → **STOP. Do not start.** Report the unresolved gates and hand back to `plan-decision-grill` (or ask the user to resolve them). Executing on unresolved decisions is the primary failure mode of this skill.
   - Treat resolved decisions as **binding constraints** for the rest of the run.
3. **Read the source-of-truth artifacts** the plan names (specs, docs, referenced code) before touching anything.
4. **Identify the steps.** Use the plan's own step/checklist structure as the execution order. Do not invent steps the plan does not contain; if the plan is missing a needed step, surface it rather than silently adding scope.

## Mode selection

Both modes execute the same steps in the same order. Only the pause cadence differs.

| Mode | Default | Behavior |
| --- | --- | --- |
| `checkpoint` | default | Finish one major step (implement + verify), report the evidence, then **stop and wait** for the user to confirm before starting the next step. |
| `auto` | on explicit request | Run every step to completion without per-step confirmation. Still stops at the safety gates below. |

Mode detection:

- `checkpoint`: default; or phrases like `단계별로`, `하나씩 진행`, `checkpoint`, `중간중간 확인`, `좋아 next 하면 진행`.
- `auto`: `auto`, `끝까지`, `한 번에`, `중간 확인 없이 완료까지`, `완료까지 자동으로`.

Common rule: `auto` never skips a step or its verification. It only skips the *confirmation prompt* between steps.

## Step loop — repeat for each major step

1. **Frame the step.** State the step's goal in one line and name which resolved decisions constrain it.
2. **Test first when it applies.** If the step has meaningful behavior to lock, write or extend a test first and confirm it fails for the right reason. Skip when a test would be ceremony (pure config, trivial wiring) — do not force tests where they carry no signal.
3. **Implement the smallest change** that satisfies the step. Stay inside the plan's scope.
4. **Verify and read the results.** Run the relevant checks and actually inspect their output — do not assume success:
   - build / compile
   - typecheck
   - lint / format
   - the tests relevant to this step
   Run what you can directly (static checks, targeted commands). For heavy runs you cannot execute (full suite, docker compose, server boot), ask the user to run them and record the returned result.
5. **Done condition.** The step is complete only when its verification passes, or the user supplies passing evidence that you record. If a check fails, fix it within scope and re-verify; if the fix needs a decision or widens scope, stop (see safety gates).
6. **Update the plan.** Check off the step and note the verification evidence at the moment it changes — not in a batch at the end.

## Reporting

- **checkpoint**: after each step, report (in Korean) — what changed, the verification evidence (build/type/lint/test results), and any remaining risk — then stop and wait for confirmation (`좋아 next` or equivalent).
- **auto**: keep brief per-step notes while progressing. End with one summary: steps completed, verification evidence, files changed, and remaining risks.

## Safety gates — stop and ask in ANY mode (including auto)

- An unresolved decision gate is encountered.
- The work would change scope beyond the plan.
- A destructive or irreversible action (data loss, schema drop, force operations).
- `git` commit / push.
- External or production impact, or anything requiring credentials.
- A step's verification fails in a way that needs a human decision rather than an in-scope fix.

## Common mistakes / anti-patterns

- Starting execution while decision gates are still unresolved.
- Moving to the next step without reading the build/test output.
- Implementing several steps at once, blurring the verification boundary for each.
- In `checkpoint` mode, starting the next step before the user confirms.
- Silently expanding scope or "improving" code the plan did not ask for.
- Committing or pushing without an explicit request.
- Reporting "done" on assumption rather than on observed passing checks.
