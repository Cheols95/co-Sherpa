#!/usr/bin/env bash
# install-skills.sh — Install this template's workflow skills.
#
# The template ships FCG *assets* in-repo, but the workflow *skills* are
# global installs and do NOT travel with a folder/clone. This script:
#   1. installs the bespoke skills (to-spec, spec-sync) from ./skills/
#      into ~/.claude/skills/  (idempotent — re-runnable), and
#   2. prints how to get the public skills (Matt Pocock set, FCG harness),
#      which it does not redistribute.
#
# Usage:
#   bash scripts/install-skills.sh            # install missing, skip existing
#   bash scripts/install-skills.sh --force    # overwrite existing bespoke skills
#   CLAUDE_SKILLS_DIR=/path bash scripts/install-skills.sh   # custom target

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/skills"
DST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

echo "=== install-skills: bespoke (repo skills/ → $DST) ==="
if [ ! -d "$SRC" ]; then
  echo "✗ no source dir: $SRC"
  exit 1
fi

mkdir -p "$DST"
installed=0
for skill_dir in "$SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  target="$DST/$name"
  if [ -e "$target" ] && [ "$FORCE" -ne 1 ]; then
    echo "  - $name — already present (skip; --force to overwrite)"
    continue
  fi
  rm -rf "$target"
  cp -R "$SRC/$name" "$DST/"
  echo "  ✓ $name installed → $target"
  installed=$((installed + 1))
done
echo "  ($installed installed/updated)"
echo

cat <<'EOF'
=== public skills (install from source — not redistributed here) ===

  Matt Pocock set — grill-with-docs, to-prd, to-issues, prototype, tdd,
                    improve-codebase-architecture, handoff:
    https://github.com/mattpocock/skills   (install per that repo's README)

  FCG harness — fcg-goal, fcg-findings, fcg-cycles:
    https://github.com/greatSumini/cc-system
      run prompt/install-findings-cycles-goals.md
      (Claude -> ~/.claude/skills, Codex -> ~/.codex/skills)

Verify:  ls ~/.claude/skills    # (+ ~/.codex/skills for Codex)
Matrix:  see README.md "필수 전역 스킬 (먼저 설치)"
EOF
