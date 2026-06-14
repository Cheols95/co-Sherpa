#!/usr/bin/env bash
# install-skills.sh -- Install this template's workflow skills from the
# in-repo backup (skills/) into the global skill homes.
#
# The template ships FCG *assets* in-repo; the workflow *skills* run from
# global installs and do NOT travel with a folder copy/clone. The repo
# skills/ directory is the SINGLE SOURCE for all 12 workflow skills
# (inert backup -- Claude/Codex never load it directly), and this script
# deploys it:
#
#   skills/<all 12>            -> ~/.claude/skills/   (Claude)
#   skills/<CODEX_SET, 4>      -> ~/.codex/skills/    (Codex / GPT)
#
# CODEX_SET = the implementation-phase skills Codex actually triggers:
# build, finding, cycle, handoff. Phase-1 planning skills
# stay Claude-only (listing them in Codex would only cost context).
#
# NOTE: several skills carry template-specific fixes (dryforge transplants,
# ladder, EXAMPLE.md pointers). Do NOT reinstall from the public sources
# (mattpocock/skills, greatSumini/cc-system) -- that would overwrite the
# fixes. The repo backup is the source of truth; credits in
# Workflow_Guideline_v1.html (footer).
#
# Usage:
#   bash scripts/install-skills.sh            # install missing, skip existing
#   bash scripts/install-skills.sh --force    # overwrite existing (deploy updates)
#   CLAUDE_SKILLS_DIR=/path  bash scripts/install-skills.sh   # custom Claude home
#   CODEX_SKILLS_DIR=/path   bash scripts/install-skills.sh   # custom Codex home
#
# Idempotent; re-run with --force after editing any skill in skills/.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/skills"
CLAUDE_DST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_DST="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

CODEX_SET="build finding cycle handoff"

if [ ! -d "$SRC" ]; then
  echo "[FAIL] no source dir: $SRC"
  exit 1
fi

codex_wants() {
  local name="$1" s
  for s in $CODEX_SET; do
    [ "$s" = "$name" ] && return 0
  done
  return 1
}

install_one() {
  local name="$1" dst_root="$2" target
  target="$dst_root/$name"
  if [ -e "$target" ] && [ "$FORCE" -ne 1 ]; then
    echo "  - $name -- already present (skip; --force to overwrite)"
    return 0
  fi
  rm -rf "$target"
  cp -R "$SRC/$name" "$dst_root/"
  echo "  + $name installed -> $target"
  installed=$((installed + 1))
}

echo "=== install-skills: repo skills/ -> $CLAUDE_DST ==="
mkdir -p "$CLAUDE_DST"
installed=0
for skill_dir in "$SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  install_one "$(basename "$skill_dir")" "$CLAUDE_DST"
done
echo "  ($installed installed/updated)"
echo

echo "=== install-skills: Codex set ($CODEX_SET) -> $CODEX_DST ==="
mkdir -p "$CODEX_DST"
installed=0
for name in $CODEX_SET; do
  if [ ! -d "$SRC/$name" ]; then
    echo "  [WARN] $name missing from $SRC -- skipped"
    continue
  fi
  install_one "$name" "$CODEX_DST"
done
echo "  ($installed installed/updated)"
echo

cat <<'EOF'
Skills are machine-global: installing once updates EVERY project on this
machine. Repo assets (scripts/, goals/ conventions, dashboard/, ...) are
per-project -- propagate those with scripts/update-workflow.sh instead.

Verify:  ls ~/.claude/skills    # and ~/.codex/skills for the Codex set
Matrix:  see Workflow_Guideline_v1.html (tab 2 "설치 위치" / tab 3 "채널 1")
EOF
