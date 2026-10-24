---
name: tk-grill
description: "Interview the user, one important question at a time, to finalize a document (intent, plan, or any design doc), patching answers into it. Use when a tk-* stage needs open decisions resolved or the user asks to grill a document."
argument-hint: "<path to document> [--task <slug|path>]"
metadata:
  version: "0.3.0"
---

# tk-grill

Given a document, find what the human must still decide before it can be treated as final, ask those questions one at a time with a recommendation, and write the answers back into the document. Facts are the agent's job; decisions are the human's.

If `grilling` (mattpocock) is installed, follow its design-tree discipline for ordering; this skill still owns the importance filter, question format, and document patching.

## Task context

Before reading or writing workflow artifacts, follow [tk-workflow Task selection](../tk-workflow/SKILL.md#task-selection). Accept `--task <slug|path>`; `<tasks>` is the resolved selected task directory, not the tasks root. Pass that path to every nested skill and peer, and include it in the next command. Standalone helper exceptions are defined there.

## Config

Read `docs/agents/tk-workflow.md` first for the intents and tasks paths; without it, use the defaults `docs/intents/` and `docs/tasks/`. Profiles below match task documents inside any slug directory under that root (and legacy flat documents), not only files directly under the root. A supplied task document path selects its own task; standalone documents need no task.

## 1. Read

Read the document, its linked documents (an intent for a plan; module specs for either), and the code it touches. Resolve from the repo every question the repo can answer, and record those as evidence rather than questions.

## 2. Collect and filter

List every gap or decision candidate. Keep only those passing the profile's importance filter. Everything else is either answered from evidence, left to the implementer, or noted as follow-up.

| Profile | Chosen when | Ask about | Leave alone |
|---|---|---|---|
| intent | `intent.md` under the configured tasks path, or a file under the configured intents path | vague success criteria, missing non-goals, scope boundary, conflicting or duplicate requirements, MUST vs SHOULD, hidden constraints, implementation detail written as requirement, several independent capabilities in one intent | how to build it, file layout, libraries |
| plan | `plan.md` under the configured tasks path | design direction (each structural proposal: the problem it removes, its reference, its cost), slice granularity and order, API / wire format, data model and migrations, authz, state machines, sync vs async, irreversible structure, conflicts with module specs, Quality bar lines that set a standard the human may want different, **new file or folder paths and names** | code style, test placement inside an approved path, checklist formatting |
| other | anything else | anything whose change would move another document or contract | wording |

Order the remaining questions as a frontier: a question whose answer depends on another open question waits for it.

## 3. Ask one question

```markdown
## Q<n> — <short title>
Why it matters: <one sentence: which contract, risk, or scope it moves>
Evidence: <files or "not found">

Question: <one question>
Options:
- A. <option> (Recommended)
- B. <option>

Recommendation: <one concrete default>
Rationale: <tradeoffs, consequences, what would flip the choice>
```

Question before recommendation. Word it so "yes" accepts the recommendation. If the answer sounds like convention rather than preference ("the standard way", "scalable"), ask once: "정당화하지 않아도 된다면 실제로 원하는 건 무엇인가요?" Wait for the answer; end the turn.

## 4. Patch

On an answer: edit the section of the document that the decision belongs to, and append one line to `## Decision Log` (`YYYY-MM-DD · Q<n> <title> → <answer> · <why>`). Create the section if absent. Recompute the frontier; return to step 3.

## 5. Stop

When the frontier is empty, report:

- decisions resolved (count, titles)
- questions answered from evidence instead of asked
- items classified as implementation detail or follow-up
- "확정 가능" or what still blocks it

Return control to the calling skill or end the turn.

## Verification

- [ ] One question per turn, recommendation attached, question first.
- [ ] Nothing asked that the repo could answer.
- [ ] Every answer landed in the document and in Decision Log.
- [ ] New file or folder paths in a plan were asked once and recorded.
