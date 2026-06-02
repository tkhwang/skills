---
name: plan-decision-grill
description: Use when a plan, design, PRD, ADR candidate, or implementation proposal should be stress-tested before coding, especially when the user asks what must be decided first, wants only important decision gates, or wants to use grill-me/grill-with-docs without debating tiny implementation details.
---

# Plan Decision Grill

## Purpose

Turn an implementation plan into a short, high-impact decision interview before coding. Resolve only decisions that materially affect contracts, architecture, data, risk, or delivery order; answer small or discoverable questions by inspecting the repo instead of asking the user.

## Operating Rule

Ask **one question at a time**, and include a recommended answer with enough explanation for the user to accept, reject, or modify it without guessing your reasoning. Do not start implementation. If a question can be answered from existing docs/code/tests, inspect those first and treat the result as evidence, not a user question.

If `$grill-with-docs` is available, use its discipline for domain language, documentation conflicts, and ADR-worthy tradeoffs. If `$grill-me` is available, use its one-question-at-a-time interrogation style. If neither is available, follow this skill directly.

## Workflow

1. **Read the source artifacts first**
   - Read the user-named plan/design/PRD.
   - Read local planning rules if present, e.g. project `CONTEXT.md`, `CONTEXT-MAP.md`, `docs/adr/**`, `docs/plans/**`, `docs/specs/**`, source-of-truth specs, status docs, or API docs named by the plan.
   - Follow whatever planning convention the repo already uses; if a plan/spec numbering scheme exists (e.g. `docs/plans/NNNN-*.md` paired with `docs/specs/NNNN-*.md`), match it.

2. **Classify potential decisions**
   - Put candidates into:
     - **Must decide before implementation** — ask the user.
     - **New file/folder naming and placement** — ask the user whenever the plan would introduce a new file, directory, spec, plan, test fixture, runner, script, generated surface, or package export. Include the exact proposed path/name and the main alternative path/name; do not silently treat this as a tiny file-layout detail.
     - **Can be decided by repo evidence** — inspect and record evidence.
     - **Implementation detail** — do not ask; leave to the implementer.
     - **Follow-up / later slice** — record but do not block current work.

3. **Apply the importance filter**
   Ask only if changing the answer later would materially affect one of:
   - public API / wire format / generated package surface
   - data model, migration, persistence, transaction, retry, or consistency semantics
   - authz/security/privacy/compliance/audit behavior
   - domain ownership, bounded-context boundary, source-of-truth conflict, or domain vocabulary
   - user-visible behavior, error semantics, lifecycle/state machine behavior
   - latency/performance/SLO, queue vs synchronous execution, external side effects
   - test strategy that changes what correctness means
   - irreversible or hard-to-reverse architecture choices
   - new file/folder names, directory placement, and package/export surface placement for any artifact the plan introduces

   Do **not** ask about obvious code style, straightforward test placement inside an already-approved path, mechanical checklist items, or choices already locked by repo conventions. New file or folder names and locations are an explicit exception: ask once, then record the resolved path/name in the plan.

4. **Ask one decision question**
   Use this compact shape. Put the **question before the recommendation** so the user sees the decision first and the recommendation as guidance, not a hidden conclusion.

   ```markdown
   ## Decision N — <short title>

   Why it matters: <contract/risk in one sentence>
   Evidence: <files/lines or "not found" summary>

   Question: <one question only>
   Options:
   - A. <option A; mark the recommended option with "(Recommended)">
   - B. <option B>

   Recommendation: <one concrete default>
   Recommendation rationale: <detailed reasoning, tradeoffs, implementation consequences, and why this is better than the main alternative>
   ```

   Prefer yes/no or A/B questions. Include the default path you recommend as an option, but do not lead with it. For new artifacts, make the question explicitly choose the file/folder path and name (for example, `docs/specs/payments-webhook.md` vs a feature-local spec path). The recommendation rationale should be detailed enough to cover the contract impact, tradeoffs, expected implementation consequences, and what would make you choose the other option. Wait for the answer before continuing.

5. **Record resolved decisions immediately**
   - Patch the plan if the user asked for plan updates or the session is explicitly plan-editing.
   - Use a `## Decision Gates` / `## 결정 필요 사항` section or checklist when the plan has no better place.
   - Keep wording current-contract oriented. Do not create an ADR unless the choice is hard to reverse, surprising without context, and a real tradeoff.

6. **Stop condition**
   Stop when no high-impact unresolved decisions remain. Return:
   - decisions resolved
   - questions deliberately not asked because repo evidence answered them
   - follow-up/later-slice items
   - whether implementation can start under the current plan

## Decision Gate Template

```markdown
## Decision Gates

- [ ] <decision title>
  - Impact: <API/data/authz/lifecycle/performance/etc.>
  - Current evidence: `<file>` / code path / missing evidence
  - Recommended default: <answer>
  - Recommended rationale: <detailed why, tradeoffs, and alternative considered>
  - Status: unresolved / resolved: <answer>
```

## Common Mistakes

- Leading with the recommendation before the question. Ask the decision question first, then give the recommendation and rationale.
- Giving a bare recommendation without explaining why. Always include the reasoning, tradeoffs, implementation consequences, and the main alternative.
- Asking every possible design question. Only ask high-impact blockers.
- Asking the user questions that code/docs can answer.
- Turning the interview into implementation.
- Treating plan structure tasks as decisions. Checklist or template compliance is usually implementation/planning hygiene, not a decision gate; however, newly introduced file/folder names and locations are decision gates and must be asked once.
- Creating ADRs for obvious or easily reversible choices.
