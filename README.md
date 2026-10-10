# skills

tkhwang's personal [agent skills](https://docs.claude.com/en/docs/claude-code/skills) for Claude Code, Codex, and other skill-aware agents. The main piece is **tk workflow**: a staged, document-driven way to take one change from intent to signoff. It runs with one agent, and other agents join for review and debate when you ask.

**English** | [한글](README.ko.md)

<p align="center">
  <img src="./assets/readme/tk-workflow.svg" width="100%" alt="tk workflow: five stages (intent, plan, implement, verify, signoff) run left to right with a human approval gate between each; runs with one agent, others join for review and debate; intents are permanent, tasks are per piece of work, specs describe current behaviour">
</p>

## What it is

- **Files are the state.** Each stage reads a document and writes a document. Where work stands is derived from `docs/`, never from conversation memory, so any session can pick it up.
- **A human gate at every stage.** A stage saves its artifact, prints a summary, and ends the turn. The next stage starts only on an explicit "next".
- **Multi-agent review and debate.** The flow runs with one agent. Say `review` or `debate` and other agents (claude, codex, grok) read the artifact or argue a decision, read-only; their answers land in files, and one agent still does all the editing.
- **The agent never commits.** It reads git, it does not write it. Commits, pushes, and branches are yours.

## Skills

### Single agent · workflow

| Skill | Stage | What it does |
|-------|-------|--------------|
| [`tk-setup`](tk-setup/) | once per repo | Explores the repo and writes `docs/agents/tk-workflow.md`: layout, docs paths, module codes, verify commands, peers. |
| [`tk-workflow`](tk-workflow/) | hub | Derives the current stage from the files, routes to the next skill, and drives the flow with `next` / `revise:` / `auto …` / `review` / `debate`. |
| [`tk-intent`](tk-intent/) | [0] | You write the intent draft (`AGENT001-slug.md`); it reads it against the code, asks the important gaps, numbers requirements as `R1`, `R2`, … |
| [`tk-plan`](tk-plan/) | [1] | Turns the intent into `docs/tasks/plan.md` + `todo.md`: vertical slices, each Backend → Frontend, with an R-id coverage matrix and no open decisions. |
| [`tk-implement`](tk-implement/) | [2] | Works `todo.md` in order, checking boxes with evidence. Every Backend / Frontend sub-phase ends with a `tk-verify phase` checkpoint that it fixes itself. Stops after each sub-phase (`auto`, the default), after each slice (`slice`), or at the end (`all`). |
| [`tk-verify`](tk-verify/) | [3] | Runs the repo's typecheck, lint (warnings fail), format check, tests, and the plan's behaviour checks; records results per R-id in `plan.md`. With `phase` / `slice` it is the mid-build checkpoint: same commands, scoped to what was just built, one line in `todo.md`. |
| [`tk-signoff`](tk-signoff/) | [4] | Traces every R-id through plan, diff, and verification. Go / No-Go. On Go: appends the intent Outcome, updates module specs, empties `docs/tasks/`. |

### Single agent · other

| Skill | What it does |
|-------|--------------|
| [`tk-grill`](tk-grill/) | Asks the unresolved decisions in a document one at a time, with a recommendation, and patches answers in. Used by `tk-intent` and `tk-plan`; works on any design doc on its own. |

### Multi-agent

Other agents join as read-only peers. The orchestrator stays the one agent that edits.

| Skill | What it does |
|-------|--------------|
| [`tk-multi-review`](tk-multi-review/) | Peer agents (claude, codex, grok) review the artifact awaiting approval, each in its own process. Findings are triaged into patches, `tk-grill` questions, or deferred notes. |
| [`tk-multi-debate`](tk-multi-debate/) | Peer agents argue one open decision in two written rounds. The orchestrator synthesizes with evidence; the human decides through `tk-grill`. |

## How one change flows

```text
/tk-setup                       once per repo
(you write docs/intents/AGENT001-tenant-export.md)
/tk-intent AGENT001             interview → requirements R1…Rn
next                            → /tk-plan: slices, decisions, coverage
review                          → codex and grok read plan.md; findings patched or asked
next                            → /tk-implement: Slice 1 Backend … stop
next                            → Slice 1 Frontend … stop … (`slice`: stop per slice · `all`: run to the end)
next                            → /tk-verify: tsc · eslint · prettier · tests
next                            → /tk-signoff: Go → specs updated, tasks emptied
git commit                      yours
```

After the first `/tk-workflow` or stage command in a session, the plain words `next`, `revise: …`, `slice`, `all`, `review`, `debate`, `status`, and `stop` keep the flow moving. Hedged answers ("looks fine") are not approval; the driver asks again.

## Documents

| Path | Lifetime | Holds |
|------|----------|-------|
| `docs/intents/<MODULE><NNN>-<slug>.md` | permanent, one per change | why, what, non-goals, success criteria, `R`-numbered requirements, decision log, outcome |
| `docs/tasks/plan.md` | current work only | decisions, scope, slices, verification plan, R-id coverage, verification results |
| `docs/tasks/todo.md` | current work only | `## Slice N` → `### Backend` / `### Frontend` → checkbox tasks with evidence |
| `docs/tasks/reviews/`, `docs/tasks/debates/` | current work only | each peer's prompt and answer, the triage, the debate rounds and synthesis |
| `docs/specs/<module>/` | permanent | how each module behaves now, written in timeless language |
| `docs/agents/tk-workflow.md` | per repo | the configuration `tk-setup` writes |

`plan.md`, `todo.md`, `reviews/` and `debates/` are overwritten per piece of work and emptied at signoff; git history is the archive. Repos that already lay docs out differently keep their layout through `tk-setup`.

## Peer agents

`tk-multi-review` and `tk-multi-debate` run other agents **headless, read-only, one process each**: `claude -p`, `codex exec -s read-only`, `grok -p`. The prompt is a self-contained file, the answer is a file, and only the orchestrating agent edits anything. Which agents take part is a `## Peers` table that `tk-setup` writes from what is installed. Inside [herdr](https://herdr.dev) the same commands run in a sibling pane so you can watch; outside herdr they run directly. Nothing else changes.

## Install

```bash
# all skills, user-level, every supported agent
npx skills add tkhwang/skills -g

# just the tk workflow
npx skills add tkhwang/skills -s tk-setup,tk-workflow,tk-intent,tk-grill,tk-plan,tk-implement,tk-verify,tk-signoff,tk-multi-review,tk-multi-debate -g

# later
npx skills update
```

Then, in a project: run `/tk-setup`, write your first intent, and run `/tk-intent`.

`tk-grill` works on its own. If [`mattpocock/skills`](https://github.com/mattpocock/skills) is installed, it follows that repo's `grilling` discipline for question ordering.

## Develop

Clone this repo and run [`link.sh`](link.sh) instead of `npx skills add`, so edits flow straight to git:

```bash
./link.sh                 # link every skill
./link.sh tk-plan         # link one
```

It creates `~/.agents/skills/<name>` → this repo, and `~/.claude/skills/<name>`, `~/.codex/skills/<name>` → that hub. Re-run after adding a skill folder; it is idempotent.

## Credits

Shaped by [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (the `tasks/plan.md` + `todo.md` convention, stage gating, clean-baseline checks) and [mattpocock/skills](https://github.com/mattpocock/skills) (grilling as a design-tree interview, per-repo `docs/agents/` config, writing for agents).
