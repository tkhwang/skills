# skills

tkhwang's personal [agent skills](https://docs.claude.com/en/docs/claude-code/skills).

Each top-level folder is one skill (`<name>/SKILL.md`), usable by Claude Code, Codex, and other skill-aware agents.

## Skills

| Skill | Description |
|-------|-------------|
| [`plan-decision-grill`](plan-decision-grill/) | Stress-test a plan/design/PRD before coding by surfacing only the important decision gates. |
| [`plan-execute`](plan-execute/) | Execute an approved plan step by step in `auto` or `checkpoint` mode, verifying build/type/lint/test results at each step. |

`plan-decision-grill` works standalone. Optionally, installing [`mattpocock/skills`](https://github.com/mattpocock/skills) gives it `grill-me` and `grill-with-docs` to lean on for a sharper one-question-at-a-time interrogation:

```bash
npx skills add mattpocock/skills -s grill-me,grill-with-docs -g
```

## Install

Use the [`skills`](https://github.com/vercel-labs/skills) CLI:

```bash
# all skills, global (user-level), all agents
npx skills add tkhwang/skills -g

# a specific skill only
npx skills add tkhwang/skills -s plan-decision-grill -g

# later, pull the latest version
npx skills update
```

This symlinks the skills into your agent dirs (`~/.claude/skills`, `~/.codex/skills`, …) and records them in `.skill-lock.json`. Pass `--copy` if you want copies instead of symlinks.

## Develop

On the machine where you author these skills, **don't** use `npx skills add` — it copies the files, decoupling them from this working tree (edits no longer flow to git). Instead clone and run [`link.sh`](link.sh):


`link.sh` symlinks every skill here into the shared hub (`~/.agents/skills/<name>`) and into each agent dir (`~/.claude/skills`, `~/.codex/skills`). Edits to a skill are then live immediately, and `git push` publishes them. Re-run `./link.sh` any time after adding a new skill folder (it's idempotent).

It creates this symlink chain (arrows = "points at"):

```
~/.claude/skills/<name>  ──┐
                           ├──→  ~/.agents/skills/<name>  ──→  <repo>/<name>
~/.codex/skills/<name>   ──┘         (hub)                      (real, git working tree)
```

Per-agent dirs point at the hub (relative), and the hub points at this repo (absolute). `link.sh` creates all three links.

Pass skill names to link only those:

```bash
./link.sh                 # all skills (default)
./link.sh plan-execute    # just one
```

