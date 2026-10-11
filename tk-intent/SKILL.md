---
name: tk-intent
description: "Stage [0] of the tk workflow: scaffold an intent file from the template for the human to write, then strengthen the human-written draft (why, what, non-goals, success criteria, R-id requirements) through a focused interview. Use when the user runs it or tk-workflow routes to it."
argument-hint: "[<MODULE> <title> [ko|en] | <path or MODULE###-slug>]"
metadata:
  version: "0.3.0"
---

# tk-intent

Two visits, one file. First visit: `/tk-intent <MODULE> <title> [ko|en]` (or bare `/tk-intent`, which asks for those three) copies the template to a new intent file and ends the turn; the human writes the draft. Second visit: `/tk-intent <ID>` reads the draft against the codebase, interviews the human about what is missing or ambiguous, and patches the document in place. It never generates an intent from a one-line request.

## Config

Read `docs/agents/tk-workflow.md` first (intents path, module codes, document language). If missing, show defaults and ask once per session, pointing at `/tk-setup`.

## Path and filename

`<intents path>/<MODULE><NNN>-<slug>.md`. The intents path comes from the config's `## Docs` → `intents:` line and may contain `{module}`, replaced with the lowercase module code. Create the directory if it does not exist.

| config `intents:` | module | file |
|---|---|---|
| `docs/intents/` | AGENT | `docs/intents/AGENT001-tenant-export.md` |
| `docs/{module}/intents/` | AGENT | `docs/agent/intents/AGENT001-tenant-export.md` |

- `MODULE`: uppercase code from the config's Modules table, or from existing intent filenames. Given as an argument, no question. Unknown: show existing codes and ask once (new code → offer to add it to the config).
- `NNN`: three digits, per module, max existing + 1, scanned in the resolved intents directory for that module.
- `slug`: short kebab-case English, derived from the title (translate if the title is not English). A title given as a single kebab-case token (`quote-approval-flow`) is used as the slug verbatim and also as the H1 title. Chosen once, never renamed.

## Template

`templates/intent.md` (Korean guide comments, the default) and `templates/intent.en.md` (English), next to this `SKILL.md`. Language is chosen in this order: an explicit `ko` / `en` as the last argument → the config's document language if it is `ko` or `en` → `ko`. Placeholders: `{{ID}}`, `{{SLUG}}`, `{{TITLE}}`, `{{DATE}}` (now, UTC ISO 8601 `YYYY-MM-DDTHH:MM:SS.sssZ`, e.g. `2026-10-11T03:38:53.000Z`; fills both `created` and `updated`).

Sections, in order: Background, Goal, Non-goals, Success criteria, Constraints, Requirements (human writes these), then Open questions, Planning hints, Decision Log (this skill and `tk-grill` fill these). Each section opens with an HTML guide comment telling the human what belongs there. `## Outcome` is appended by `tk-signoff` and marks the intent done.

## 0. No or partial argument: ask

Bare `/tk-intent`:

1. List intents without `## Outcome` that no `plan.md` names. If there are any, ask first: continue one of them (list them as options) or start a new one. Picking one goes to step 2 (Locate).
2. New intent, or no open intents: ask the three fields. One question per field, or one form if the agent has a form tool (Claude Code: `AskUserQuestion`); wait for each answer.

```text
module:   <options: codes from the config's Modules table, plus "new code">
title:    <free text; Korean or English>
language: ko (Recommended) | en
```

An unknown module code → offer to add it to the config (name, code locations) before continuing. Then go to step 1 with those values.

Partial argument (`<MODULE>` only, or `<MODULE> <title>` without language): ask only the missing fields; language is asked only when the config has no document language. Never ask what the argument already gave.

## 1. Scaffold (first visit)

Argument is `<MODULE> <title> [ko|en]` (typed, or collected in step 0) and no file with that title's slug exists under the module. The first token is the module code; a last token that is exactly `ko` or `en` is the template language; everything between is the title.

```text
/tk-intent AGENT 테넌트 데이터 내보내기        → <intents path>/AGENT001-tenant-export.md, Korean template
/tk-intent AGENT Tenant data export en       → same file, English template
```

1. Resolve the intents directory from the config (`{module}` → `agent`), then compute `ID`, `SLUG`, `DATE`; keep `TITLE` exactly as given (without the language token). `DATE` is the current UTC time in ISO 8601 (`date -u +%Y-%m-%dT%H:%M:%S.000Z`), never a bare date.
2. Copy the template to that path, substituting the placeholders. Create missing directories. Change nothing else; the guide comments stay.
3. Print the path, the section list the human is expected to fill (Background … Requirements), and the command to come back with (`/tk-intent <ID>`).
4. **End the turn.** Do not fill any section, do not start the interview.

Done when the file exists and the human has the path.

## 2. Locate (second visit)

- Argument is a path, `MODULE###-slug`, or a bare `MODULE###` that matches exactly one file → open that file.
- Pasted draft in chat → save it to the computed filename first (frontmatter from the template, body as pasted), then continue.
- No argument → handled in step 0 (continue an open intent, or ask module / title / language for a new one).

**Still a scaffold?** A section is empty when it holds only its guide comment, blank lines, or a bare `- `. If Background, Goal, Success criteria and Requirements are all empty, the human has not written yet: say so, repeat the path and the section list, and end the turn. Do not interview an empty file and do not write the draft for them.

Done when one intent file is open and the human has written content in it.

## 3. Read against the codebase

Read the draft, then (read-only) the specs and code of the modules it names. Note where the draft assumes something the code contradicts, and where an answer the draft lacks can be found in the repo. Facts come from the repo; only decisions go to the human.

## 4. Interview

Invoke `tk-grill` on the intent file. It applies the intent profile: ambiguous success criteria, missing non-goals, scope boundaries, conflicting requirements, MUST/SHOULD, hidden constraints, implementation detail posing as requirement, and whether the intent bundles several independently testable capabilities (then propose splitting into several intents). Sections the human left empty are the first candidates. Answers are patched into the file by `tk-grill` with a Decision Log entry.

Done when `tk-grill` reports the frontier empty.

## 5. Finalize the document

- Keep the human's wording wherever it still holds; patch, do not rewrite.
- Number requirements `R1`, `R2`, … with `MUST` / `SHOULD` and one observable acceptance criterion each.
- Move implementation hints (file names, libraries, schemas) the human wrote into `## Planning hints`. They inform `tk-plan` without becoming requirements.
- Leave genuinely open items under `## Open questions`.
- Set frontmatter `updated` to the current UTC ISO 8601 timestamp whenever this skill patches the file.
- Remove the guide comment from every section that now has content, and the header comment under the title. A section that is legitimately empty (no non-goals, no open questions) keeps a one-line `_None._` instead of the comment.

Done when every requirement has an R-id and an acceptance criterion, the document contains no implementation detail outside Planning hints, and no guide comment remains.

## 6. Stop

Print a five-line summary (goal, R-id count, non-goals, open questions, path) and the next command (`/tk-plan` or `다음`; `리뷰` to have peers read it first). End the turn.

## Verification

- [ ] Bare `/tk-intent` asked module, title, language (one at a time or one form) and did not guess any of them.
- [ ] Scaffold visit wrote only the template with placeholders filled, under the config's intents path with `{module}` resolved, then ended the turn.
- [ ] The human wrote the draft; this skill asked and patched. An empty scaffold was handed back, not filled.
- [ ] Every requirement has an R-id, MUST/SHOULD, and an acceptance criterion.
- [ ] No file paths, library choices, or schemas outside Planning hints.
- [ ] No guide comments left in the finalized document.
- [ ] Turn ended after the summary; `tk-plan` was not started.
