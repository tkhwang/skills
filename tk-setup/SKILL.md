---
name: tk-setup
description: "Configure a repo for the tk-* workflow skills: layout, docs paths, module codes, verify commands. Run once per repo."
argument-hint: "[optional notes about the repo]"
disable-model-invocation: true
metadata:
  version: "0.1.0"
---

# tk-setup

Write the per-repo configuration that every `tk-*` skill reads first: `docs/agents/tk-workflow.md`, plus a pointer block in `CLAUDE.md` / `AGENTS.md`. Explore, draft, confirm the few items that genuinely branch, then write.

## 1. Explore

Read before asking. Collect:

- **Repo shape**: `git remote -v`, `git rev-parse --show-toplevel`. Is the working folder itself a repo, or a folder holding several repos (`backend/`, `frontend/` each with `.git`)?
- **Packages**: every `package.json` (or `pyproject.toml`, `go.mod`, `Cargo.toml`) within two levels; lockfile → package manager; `pnpm-workspace.yaml` / `workspaces` field.
- **Commands**: each package's scripts for typecheck, lint, format, test; checked-in wrappers; CI workflows under `.github/workflows/` and what they actually run. CI is the source of truth for what gates merges.
- **Existing docs**: `docs/` tree; any `intents/`, `specs/`, `tasks/`, `plans/` folders, possibly nested as `docs/<module>/…`; existing intent filenames and their module codes (`AGENT001-…` → `AGENT`).
- **Existing agent config**: `CLAUDE.md`, `AGENTS.md`, an `## Agent skills` block, `docs/agents/*.md` from other skill sets.

Done when you can fill every section of the config template below with either a discovered value or a clearly marked question.

## 2. Draft and ask

Show the filled draft. Then ask only the items exploration could not settle, one at a time, recommended answer first so "yes" accepts it:

- **Layout** when the folder holds several packages or repos: which are in scope, and where is the **docs home** (recommended: the working folder's own `docs/`; if that folder is not a git repo, recommend `git init` there so `docs/tasks/plan.md` history survives as the archive).
- **Docs paths** when the repo already nests docs by module (`docs/<module>/intents/`): keep that pattern (`{module}` placeholder) or use flat `docs/intents/`.
- **Module codes** when none exist yet: ask for the initial list (uppercase code, short name, code locations). An empty table is acceptable; `tk-intent` adds codes on first use.
- **Language** for conversation and documents: default `ko` / follow existing docs.

Skip any question whose answer exploration already gave.

## 3. Write

Write `docs/agents/tk-workflow.md` from the template. Then add the pointer:

- Edit `CLAUDE.md` if it exists, else `AGENTS.md`; if neither exists, ask which to create.
- If an `## Agent skills` block exists, add a `### tk-workflow` subsection inside it; otherwise create the block. Update in place on re-runs; leave surrounding content untouched.

```markdown
## Agent skills

### tk-workflow

Staged delivery workflow (intent → plan → implement → verify → signoff). Config: `docs/agents/tk-workflow.md`.
```

Done when both files exist and the config has no unresolved question marks. Tell the user the config is plain markdown they may edit by hand, and that re-running `/tk-setup` is only needed when the layout changes.

## Config template

```markdown
# tk-workflow config

## Layout
- kind: single-package            # single-package | multi-package
- docs home: .                    # folder that holds docs/
- packages:
  - app → .                       # name → path (one row per package)

## Docs
- intents: docs/intents/          # may contain {module} (lowercase module code)
- specs:   docs/specs/{module}/   # one file per topic inside a module
- tasks:   docs/tasks/            # plan.md and todo.md, always one location

## Modules
| code  | name | code locations |
|-------|------|----------------|
| AGENT | …    | src/agent      |

## Verify
| package | typecheck | lint | format | test |
|---------|-----------|------|--------|------|
| app     | pnpm tsc --noEmit | pnpm eslint . --max-warnings 0 | pnpm prettier --check . | pnpm test |

## Language
- conversation: ko
- documents: ko                  # or "follow existing docs"
```

## Verification

- [ ] Every `Verify` command was found in scripts or CI, not guessed.
- [ ] `Modules` codes match existing intent filenames, if any.
- [ ] The pointer block is in exactly one of `CLAUDE.md` / `AGENTS.md`.
