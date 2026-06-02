#!/usr/bin/env bash
# link.sh — link the skills in this repo (working tree) into the local agent dirs.
#
# Usage:
#   ./link.sh                    link ALL skills in this repo (default)
#   ./link.sh plan-execute       link only the named skill
#   ./link.sh plan-execute foo   link several skills by name
#
# Authoring workflow: develop skills here, run ./link.sh once, and Claude Code /
# Codex use them live via symlinks. Edits are effective immediately and
# `git push` publishes them. This is the DEV counterpart to the `npx skills add`
# consumer install documented in the README.
#
# Idempotent: safe to re-run any time (after adding a new skill folder, or to
# restore symlinks if something replaced them with copies).
#
# Resulting symlink chain (arrows = "points at"):
#
#   ~/.claude/skills/<name>  ──┐
#                              ├──→  ~/.agents/skills/<name>  ──→  <repo>/<name>
#   ~/.codex/skills/<name>   ──┘         (hub)                      (real, git working tree)
#
# i.e. per-agent dirs point at the hub (relative), and the hub points at this
# repo (absolute). link.sh creates all three links.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB="$HOME/.agents/skills"
# Per-agent skill dirs that should point at the hub. Add more as needed.
AGENT_DIRS=("$HOME/.claude/skills" "$HOME/.codex/skills")

mkdir -p "$HUB"

# Decide which skills to link: named args, or all folders with a SKILL.md.
names=()
if [ "$#" -gt 0 ]; then
  for name in "$@"; do
    if [ -f "$REPO/$name/SKILL.md" ]; then
      names+=("$name")
    else
      echo "skip: no '$name/SKILL.md' in $REPO" >&2
    fi
  done
else
  for skill_md in "$REPO"/*/SKILL.md; do
    [ -e "$skill_md" ] || continue
    names+=("$(basename "$(dirname "$skill_md")")")
  done
fi

if [ "${#names[@]}" -eq 0 ]; then
  echo "Nothing to link."
  exit 0
fi

for name in "${names[@]}"; do
  # Hub link (absolute) -> repo working tree.
  rm -rf "$HUB/$name"
  ln -s "$REPO/$name" "$HUB/$name"

  # Per-agent links (relative) -> hub.
  for adir in "${AGENT_DIRS[@]}"; do
    [ -d "$adir" ] || continue
    rm -rf "$adir/$name"
    ln -s "../../.agents/skills/$name" "$adir/$name"
  done
done

# Linked skills are now repo-managed, not npx-managed: drop any stale entries
# from npx's lock so `npx skills list/update` doesn't treat them as installed.
lock="$HOME/.agents/.skill-lock.json"
if [ -f "$lock" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$lock" "${names[@]}" <<'PY'
import json, sys
lock, names = sys.argv[1], set(sys.argv[2:])
d = json.load(open(lock))
skills = d.get("skills", {})
removed = sorted(n for n in names if n in skills)
for n in removed:
    del skills[n]
if removed:
    json.dump(d, open(lock, "w"), indent=2, ensure_ascii=False)
    print("  dropped from npx lock:", ", ".join(removed))
PY
fi

echo "Linked ${#names[@]} skill(s) from $REPO:"
for name in "${names[@]}"; do echo "  - $name"; done
