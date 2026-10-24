---
name: tk-multi-review
description: "Have peer agents (claude, codex, grok) review the current tk stage's artifact: intent, plan, implementation diff, or verification record. Collects each review as a file, triages findings into patches or tk-grill questions. Use when the user asks for a peer or multi-agent review of a stage, or the driver receives 리뷰 / review."
argument-hint: "[intent | plan | implement | verify | <path>] [peer…] [--task <slug|path>]"
metadata:
  version: "0.3.0"
---

# tk-multi-review

Ask one or more peer agents to read the artifact of the current stage and report findings. Each peer runs headless, read-only, in its own process; its answer lands in a file. This skill then triages: facts the artifact gets wrong are patched, decisions go to `tk-grill`, the rest is recorded. Peers never edit; only the orchestrating agent writes.

## Task context

Before reading or writing workflow artifacts, follow [tk-workflow Task selection](../tk-workflow/SKILL.md#task-selection). Accept `--task <slug|path>`; `<tasks>` is the resolved selected task directory, not the tasks root. Pass that path to every nested skill and peer, and include it in the next command. Standalone helper exceptions are defined there.

## Config

Read `docs/agents/tk-workflow.md` first: `## Peers` (name, kind, role, optional command override) and the docs paths. `<tasks>` below is the selected task directory; peer files live under `<tasks>/reviews/`. No `## Peers` → ask once which of `claude`, `codex`, `grok` to use (list those found on `PATH`), offer to add the table to the config, then continue. Peers whose role is `review` or `any` take part; a `[peer…]` argument restricts to those names.

## 1. Target

The argument names the stage or a path. No argument → derive the stage from the files the way `tk-workflow` does, and review the artifact the human is about to approve.

| Stage | Artifact the peer reads | Also in scope |
|---|---|---|
| `intent` | `<tasks>/intent.md` (a legacy intent when that file does not exist) | specs of the modules it names |
| `plan` | `plan.md`, `todo.md` | the intent |
| `implement` | the change as `tk-verify` §1 defines it: per repository, `git diff` against its `base:` entry in `todo.md` plus untracked files | `todo.md`, `plan.md`, the intent |
| `verify` | `plan.md` `## Verification` | `todo.md`, the raw outputs it cites |
| `<path>` | that file | documents it links |

`verify` here reviews the verification record. For peers to audit the finished work itself, run `tk-verify <peer…>`, which reuses §4 below with its own audit prompt.

Done when the artifact paths and the rubric row are fixed.

## 2. Rubric

| Stage | Peer looks for |
|---|---|
| intent | success criteria that cannot be observed, missing non-goals, requirements that contradict each other or the code, implementation detail posing as requirement, several capabilities bundled in one intent |
| plan | R-ids with no task or tasks with no R-id, slices that are not independently demoable, decisions still open, paths or contracts that conflict with specs, hidden migrations or authz gaps, risks missing from the table, a minimal patch where the structure itself is the problem, structural proposals with no reference or no problem to remove, Quality bar lines that cannot be checked against a diff |
| implement | changes no task cites, drift from plan decisions, work below the Quality bar (happy path only, a structure the plan replaced still in use), missing or ceremonial tests, error paths and edge cases, security or data-loss hazards, leftovers cleanup missed, evidence claimed in `todo.md` that the diff does not support |
| verify | commands not traceable to repo config, warnings passed as success, behaviour checks that do not prove their R-id, `human` rows that could have been automated, audit rows marked `done` or `sound` without `file:line` evidence, peer findings counted without being checked in the repo |

## 3. Prompt

The peer cannot see this conversation, so the prompt is self-contained and written to `<tasks>/reviews/<stage>-<peer>.prompt.md`:

```markdown
You are reviewing, read-only, inside the repository at <abs repo path>.
Do not edit any file. Answer in <document language>.

Read, in this order: <artifact paths>. For context you may read: <in-scope paths>.
Review against this rubric: <rubric row>.

Report in exactly this format:
## Findings
- [blocker|should|nit] <where: file:line or section> — <claim> · evidence: <what you read> · fix: <one sentence>
## Questions for the human
- <a decision only the human can make, with the options you see>
## Verdict
<approve | approve with fixes | rework> — <one sentence>
```

Done when the prompt file exists and names only paths that exist.

## 4. Run

Default commands, one per kind. The `command` column in `## Peers` overrides; the installed binary's `--help` is the authority when a flag has changed. An override must keep the peer read-only: it has to carry the kind's read-only flag (`--allowedTools` without Write/Edit/Bash-write for claude, `-s read-only` for codex, `--permission-mode plan` for grok) or an equivalent. Before running an override, check for that flag; if it is missing, do not run it, name the flag, and fall back to the default command.

| kind | command (stdout → result file) |
|---|---|
| claude | `claude -p --output-format text --allowedTools "Read,Grep,Glob,Bash(git diff *),Bash(git log *)" "$(cat <prompt>)" > <result>` |
| codex | `codex exec -s read-only -C <repo> -o <result> "$(cat <prompt>)"` |
| grok | `grok -p "$(cat <prompt>)" --output-format plain --permission-mode plan --cwd <repo> > <result>` |

Where it runs:

- **Inside herdr** (`HERDR_ENV=1`): split a sibling pane (`herdr pane split --current --direction right --cwd "$PWD" --no-focus`), run the command there (`herdr pane run`, or the `herdr_pane_run` MCP tool), and wait for the process to exit (`herdr wait-output` / `herdr_wait_output`). The human watches the pane; the result is still the file.
- **Elsewhere**: run the command directly and wait for it to exit.

Several peers run concurrently. Result file: `<tasks>/reviews/<stage>-<peer>.md`. Prepend a header once the process exits:

```markdown
reviewer: codex · stage: plan · run: 2026-10-10 14:02 · artifact: docs/tasks/<slug>/plan.md · command: default
```

Timeout 10 minutes per peer; on timeout or an empty file, record `result: no answer` in the header and move on.

Done when every peer has a result file.

## 5. Triage

Read every result file. For each finding, decide and append a `## Triage` list to that result file (`- <finding> → accepted | asked | deferred | rejected: <why>`):

- **accepted**: the artifact states something the repo contradicts, or omits something the rubric requires → patch the artifact now, with the same care as a `revise:` request (keep the human's wording, patch do not rewrite). At the `implement` stage the artifact is a diff, so the patch goes to the source files the finding names, inside the plan's scope and the task's files: fix, re-run that task's `verify:` command, update its evidence in `todo.md`. A fix that would widen scope is `deferred` or `asked`, not applied. A finding that proposes a different design or structure (a better pattern, a Design direction change, replacing a minimal patch) is a decision: `asked`, never `accepted`.
- **asked**: a decision → add it as `open:` to the artifact's `## Decision Log` (intent: `## Open questions`) and invoke `tk-grill` on the artifact after triage.
- **deferred**: real but outside this stage or this intent → `plan.md` `## Discovered` (or the intent's `## Open questions`) as `NOTICED, NOT TOUCHED`.
- **rejected**: wrong or already handled → say why in one sentence. Rejecting a `blocker` requires evidence from the repo.

Then append one line to the artifact's `## Decision Log`: `YYYY-MM-DD · review(<peers>) → accepted n · asked m · deferred k · rejected j`.

Done when no finding lacks a disposition and `tk-grill` has run for every `asked` item.

## 6. Stop

Print per peer the verdict and counts, the patches applied, and the questions raised. The stage artifact is still awaiting the human's approval: print `다음` to approve or `수정: …` to change. End the turn.

## Verification

- [ ] Every peer ran read-only in its own process; no peer edited the repo.
- [ ] Every finding has a disposition in the result file; decisions went through `tk-grill`.
- [ ] Patches touched only the current stage's artifact, or at `implement` only source files inside the plan's scope with their task evidence updated.
- [ ] The stage was not advanced; the turn ended at the summary.
