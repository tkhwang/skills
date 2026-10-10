---
name: tk-intent
description: "Stage [0] of the tk workflow: strengthen a human-written intent document (why, what, non-goals, success criteria, R-id requirements) through a focused interview, or scaffold an empty one. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[<MODULE> <title> | <path or MODULE###-slug>]"
metadata:
  version: "0.1.0"
---

# tk-intent

The human writes the first draft of an intent. This skill reads it against the codebase, interviews the human about what is missing or ambiguous, and patches the document in place. It never generates an intent from a one-line request.

## Config

Read `docs/agents/tk-workflow.md` first (intents path, module codes, languages). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## Filename

`<intents path>/<MODULE><NNN>-<slug>.md`, e.g. `docs/intents/AGENT001-tenant-export.md`.

- `MODULE`: uppercase code from the config's Modules table, or from existing intent filenames. Given as an argument, no question. Unknown: show existing codes and ask once (new code → offer to add it to the config).
- `NNN`: three digits, per module, max existing + 1.
- `slug`: short kebab-case English. Chosen once, never renamed.

## 1. Locate or scaffold

- Argument is a path or `MODULE###-slug` → open that file.
- Argument is `<MODULE> <title>` and no matching file exists → write the template below with the frontmatter filled and every section empty, print the path, and **end the turn**. The human fills it in.
- Pasted draft in chat → save it to the computed filename first, then continue.
- No argument → the single intent without `## Outcome` not referenced by any plan; several → ask which.

Done when one intent file is open and the human has written content in it.

## 2. Read against the codebase

Read the draft, then (read-only) the specs and code of the modules it names. Note where the draft assumes something the code contradicts, and where an answer the draft lacks can be found in the repo. Facts come from the repo; only decisions go to the human.

## 3. Interview

Invoke `tk-grill` on the intent file. It applies the intent profile: ambiguous success criteria, missing non-goals, scope boundaries, conflicting requirements, MUST/SHOULD, hidden constraints, implementation detail posing as requirement, and whether the intent bundles several independently testable capabilities (then propose splitting into several intents). Answers are patched into the file by `tk-grill` with a Decision Log entry.

Done when `tk-grill` reports the frontier empty.

## 4. Finalize the document

- Keep the human's wording wherever it still holds; patch, do not rewrite.
- Number requirements `R1`, `R2`, … with `MUST` / `SHOULD` and one observable acceptance criterion each.
- Move implementation hints (file names, libraries, schemas) the human wrote into `## Planning hints`. They inform `tk-plan` without becoming requirements.
- Leave genuinely open items under `## Open questions`.

Done when every requirement has an R-id and an acceptance criterion, and the document contains no implementation detail outside Planning hints.

## 5. Stop

Print a five-line summary (goal, R-id count, non-goals, open questions, path) and the next command (`/tk-plan` or `다음`). End the turn.

## Template

```markdown
---
id: AGENT001
slug: tenant-export
created: 2026-10-10
---
# AGENT001 · Tenant data export

## Background
## Goal
## Non-goals
## Success criteria
## Constraints
## Requirements
- R1 (MUST) … — acceptance: …
## Open questions
## Planning hints
## Decision Log
```

`## Outcome` is appended by `tk-signoff` and marks the intent done.

## Verification

- [ ] The human wrote the draft; this skill asked and patched.
- [ ] Every requirement has an R-id, MUST/SHOULD, and an acceptance criterion.
- [ ] No file paths, library choices, or schemas outside Planning hints.
- [ ] Turn ended after the summary; `tk-plan` was not started.
