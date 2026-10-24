---
name: tk-intent
description: "Stage [0] of the tk workflow: scaffold the selected task folder's intent.md from the template for the human to write, then strengthen the human-written draft (why, what, non-goals, success criteria, R-id requirements, module) through a focused interview. The intent gets its ID only when it leaves docs/tasks: tk-signoff moves it to the intents folder once it ships; with archive, this skill moves a dropped one to archived/. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[<title> [ko|en] | archive [reason]] [--task <slug|path>]"
metadata:
  version: "0.6.0"
---

# tk-intent

Two visits, one file. First visit: `/tk-intent <title> [ko|en]` (or bare `/tk-intent`, which asks the title) copies the template to `<tasks>/intent.md` and ends the turn; the human writes the draft. Second visit: bare `/tk-intent` reads the draft against the codebase, interviews the human about what is missing or ambiguous, and patches the document in place. It never generates an intent from a one-line request.

`<tasks>/intent.md` is a working file, like `plan.md` and `todo.md`: it holds this task's intent in progress and has no ID yet. The intent is named when it leaves `<tasks>`: `tk-signoff` moves it to `<intents dir>/<MODULE><NNN>-<slug>.md` once it ships, and `/tk-intent archive` (step 7) moves a dropped one to `archived/`.

## Task context

Before reading or writing workflow artifacts, follow [tk-workflow Task selection](../tk-workflow/SKILL.md#task-selection). Accept `--task <slug|path>`; `<tasks>` is the resolved selected task directory, not the tasks root. Pass that path to every nested skill and peer, and include it in the next command. Standalone helper exceptions are defined there.

## Config

Read `docs/agents/tk-workflow.md` first: tasks root (`tasks_root:`, default `docs/tasks/`), intents path, module codes, document language. If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## Working file

`<tasks>/intent.md`, one per task slug. New work gets its own folder; existing task directories are never overwritten. Resume a selected task with bare `/tk-intent --task <slug>`; a title requests new work and follows the collision rule in Task selection.

## Path and filename (when the intent leaves `<tasks>`)

`<intents path>/<MODULE><NNN>-<slug>.md`. The intents path comes from the config's `## Docs` → `intents:` line and may contain `{module}`, replaced with the lowercase module code.

| config `intents:` | module | file |
|---|---|---|
| `docs/intents/` | AGENT | `docs/intents/AGENT001-tenant-export.md` |
| `docs/{module}/intents/` | AGENT | `docs/agent/intents/AGENT001-tenant-export.md` |

The ID is computed at the move: by `tk-signoff` when the intent ships, by step 7 when it is dropped. The task slug is chosen at creation and reused at the move.

- `MODULE`: frontmatter `module:`, settled in step 5. Empty → ask once, codes from the config's Modules table, recommended first. Unknown code → offer to add it to the config.
- `NNN`: three digits, per module, max existing + 1, scanned in the resolved intents directory for that module, including its `archived/` folder, so an ID is never reused.
- `slug`: the selected task folder's stable slug. For legacy flat work only, derive short English kebab-case from the title at the move. Recheck the destination and ID before moving; never overwrite another intent. Separate branches can still allocate the same numeric ID; reconcile that at integration, not by replacing a record.

The move:

1. Frontmatter: add `id: <ID>` and `slug: <slug>` above `module:`; set `updated` to the current UTC ISO 8601 timestamp.
2. H1: `# <ID> · <title>`.
3. `mv <tasks>/intent.md <target>`, creating the folder if needed. Use `mv`, not `git mv`; git stays read-only. Leave nothing at `<tasks>/intent.md`: a plain move lets git record a rename, so `git log --follow` on the new file reaches the draft's history.

Dropped intents live in `<intents dir>/archived/` under the same kind of filename (`docs/intents/archived/AGENT001-tenant-export.md`). Apart from `NNN` numbering, every lookup of intents in this skill and in the other tk-* skills ignores that folder.

## Template

`templates/intent.md` (Korean guide comments, the default) and `templates/intent.en.md` (English), next to this `SKILL.md`. Language is chosen in this order, without a question: an explicit `ko` / `en` as the last argument → the config's document language if it is `ko` or `en` → `ko`. Placeholders: `{{TITLE}}`, `{{DATE}}` (now, UTC ISO 8601 `YYYY-MM-DDTHH:MM:SS.sssZ`, e.g. `2026-10-11T03:38:53.000Z`; fills both `created` and `updated`). Frontmatter `module:` starts empty; `id` and `slug` are added at the move.

Sections, in order: Background, Goal, Non-goals, Success criteria, Constraints, Requirements (human writes these), then Open questions, Planning hints, Decision Log (this skill and `tk-grill` fill these). Each section opens with an HTML guide comment telling the human what belongs there. `## Outcome` is appended by `tk-signoff` just before the move and marks the intent done. `## Archived` is appended by step 7 just before the move.

## 0. Route

Resolve and strip `--task` by the shared Task selection contract first; for a title, choose a new task rather than inheriting the previous selection. The first remaining token exactly `archive` → step 7. A single token or path naming an intent under the intents path (`AGENT001`, `AGENT001-tenant-export`) → **Legacy intents** below. Anything else is a title, with an optional last token `ko` / `en`.

| `<tasks>` | bare `/tk-intent` | `/tk-intent <title> [ko\|en]` |
|---|---|---|
| free | ask the title (one question), then step 1 | step 1 |
| `intent.md` exists | step 2 | refuse |
| `plan.md` filled, no `intent.md` | legacy work: see Legacy intents | refuse |

**Refuse** applies only to a collision in the selected directory: name that work and offer to resume it, archive it, or choose a different slug. Other active tasks do not prevent creation. Change nothing until the collision is resolved.

## 1. Scaffold (first visit)

```text
/tk-intent 테넌트 데이터 내보내기 --task tenant-export
  → docs/tasks/tenant-export/intent.md, Korean template
/tk-intent Tenant data export en --task tenant-export
  → same destination, English alternative (not a second creation)
/tk-intent --task tenant-export
  → resume that draft
```

1. Compute `DATE` with `date -u +%Y-%m-%dT%H:%M:%S.000Z`, never a bare date. Keep `TITLE` exactly as given, without the language token.
2. Copy the template to `<tasks>/intent.md`, substituting the placeholders. Create the selected new task directory; never reuse an existing directory for a new scaffold. Change nothing else; the guide comments stay.
3. Print the path, the section list the human is expected to fill (Background … Requirements), and the command to come back with (`/tk-intent --task <slug>`).
4. **End the turn.** Do not fill any section, do not start the interview.

Done when the file exists and the human has the path.

## 2. Open the draft (second visit)

- Pasted draft in chat → if `<tasks>` is free, save it to `<tasks>/intent.md` (frontmatter from the template, H1 and body as pasted) and continue; if busy, refuse as in step 0.
- Otherwise open `<tasks>/intent.md`.

**Still a scaffold?** A section is empty when it holds only its guide comment, blank lines, or a bare `- `. If Background, Goal, Success criteria and Requirements are all empty, the human has not written yet: say so, repeat the path and the section list, and end the turn. Do not interview an empty file and do not write the draft for them.

Done when the intent is open and the human has written content in it.

## 3. Read against the codebase

Read the draft, then (read-only) the specs and code of the modules it names. Note where the draft assumes something the code contradicts, and where an answer the draft lacks can be found in the repo. Facts come from the repo; only decisions go to the human.

## 4. Interview

Invoke `tk-grill` on the intent file. It applies the intent profile: ambiguous success criteria, missing non-goals, scope boundaries, conflicting requirements, MUST/SHOULD, hidden constraints, implementation detail posing as requirement, and whether the intent bundles several independently testable capabilities. Sections the human left empty are the first candidates. Answers are patched into the file by `tk-grill` with a Decision Log entry.

A bundle is split, not carried: this intent keeps one capability, and each other one goes under `## Non-goals` as `follow-up intent: <one line>`. `tk-signoff` lists those as follow-ups; starting one now means a different task slug, with another worktree when code isolation is needed.

Done when `tk-grill` reports the frontier empty.

## 5. Finalize the document

- Keep the human's wording wherever it still holds; patch, do not rewrite.
- Number requirements `R1`, `R2`, … with `MUST` / `SHOULD` and one observable acceptance criterion each.
- Move implementation hints (file names, libraries, schemas) the human wrote into `## Planning hints`. They inform `tk-plan` without becoming requirements.
- Leave genuinely open items under `## Open questions`.
- **Module**: set frontmatter `module:` to the module whose behaviour the requirements change most, judged from the config's Modules table (code locations) and the code read in step 3. Exactly one candidate → set it without asking and name it in the summary. Several → ask once, recommended first. Unknown → offer to add it to the config. The filename carries one module; other modules the intent touches stay in the body.
- Set frontmatter `updated` to the current UTC ISO 8601 timestamp whenever this skill patches the file.
- Remove the guide comment from every section that now has content, and the header comment under the title. A section that is legitimately empty (no non-goals, no open questions) keeps a one-line `_None._` instead of the comment.

Done when every requirement has an R-id and an acceptance criterion, `module:` is set, the document contains no implementation detail outside Planning hints, and no guide comment remains.

## 6. Stop

Print a five-line summary (goal, R-id count, module, non-goals and open questions, path) and the next command (`/tk-plan` or `다음`; `리뷰` to have peers read it first). End the turn.

## 7. Archive

`/tk-intent archive [reason]` takes the intent in progress out of the workflow when it is dropped (requirements changed, replaced by other intents, no longer wanted).

1. **Locate** `<tasks>/intent.md`. Missing → nothing to archive: say so and end the turn (an older intent under the intents path is Legacy). Still a scaffold (step 2 test), with no filled plan/todo or other working artifacts → nothing was written: delete only the scaffold and remove its slug directory if empty (never the legacy root), clear its session selection and approval, spend no ID, say so, and end the turn. Otherwise continue through the archive flow.
2. **Reason**: the rest of the argument, else ask once. Intent IDs that replace it (`AGENT004`) go on their own `superseded by` line.
3. **Work in progress**: if `plan.md` is filled, show what will be discarded (checked / total boxes in `todo.md`, whether `## Verification` exists) and ask once. Yes → proceed to record and move the intent, then delete only this task's temporary artifacts using `tk-signoff` §4. Do not delete evidence before the intent is saved. No → end the turn with nothing changed. Code already changed stays; reverting it is the human's, with git. `plan.md` empty → no question.
4. **Record**: append the section below and set frontmatter `updated`. Leave out the `superseded by` line when nothing replaces it. Change nothing else in the document.

   ```markdown
   ## Archived
   - 2026-10-16T03:38:53.000Z · <reason>
   - superseded by: AGENT004, AGENT005
   ```

5. **Name and move** it to `<intents dir>/archived/<MODULE><NNN>-<slug>.md` by the Path and filename rule.
6. **Clean and stop**: after the move succeeds, delete this task's plan/todo/baseline/reviews/debates by `tk-signoff` §4 and remove its directory if empty. Create no archive copies or replacement report. Print the intent's new path and the files ready to commit. Clear this task's session selection and approval; leave other tasks untouched. End the turn.

Done when `<tasks>/intent.md` is gone and the intent is under `archived/` with an `## Archived` entry.

## Legacy intents

Intents written before this layout sit under the intents path with an ID and no `## Outcome`, and a `plan.md` may name one in its frontmatter `intent:`. They finish where they are:

- `/tk-intent <ID or path>` opens one and runs steps 3–6 on it. The only match under `archived/` → say it is archived, quote its `## Archived` entry, and end the turn; to revive it, the human moves the file back and deletes `## Archived`.
- `/tk-intent archive <ID> [reason]` runs step 7 on it; step 5 moves it into `archived/` under its existing filename. One that has `## Outcome` is refused: its record stays where it is, and removing what it built is a new intent.
- `tk-plan`, `tk-signoff` and the other stages use it when `<tasks>/intent.md` does not exist; `tk-signoff` appends `## Outcome` in place, without a move.

New intents always start in `<tasks>/intent.md`; a legacy intent is never moved into `<tasks>`.

## Verification

- [ ] Scaffold wrote only the template, placeholders filled, at `<tasks>/intent.md`, chose a stable task slug but computed no ID or module, and ended the turn.
- [ ] A busy `<tasks>` was never overwritten; the human got resume / archive / a different slug.
- [ ] The human wrote the draft; this skill asked and patched. An empty scaffold was handed back, not filled.
- [ ] Every requirement has an R-id, MUST/SHOULD, and an acceptance criterion; `module:` is set.
- [ ] No file paths, library choices, or schemas outside Planning hints.
- [ ] No guide comments left in the finalized document.
- [ ] Turn ended after the summary; `tk-plan` was not started.
- [ ] `archive` deleted an untouched scaffold without spending an ID; otherwise it appended `## Archived` with a reason, named the file and moved it under `archived/`, and deleted only the selected task's temporary artifacts after the move succeeded (with confirmation when a filled plan was present).
- [ ] `NNN` numbering counted `archived/`; every other intent lookup ignored it.
