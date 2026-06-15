#!/usr/bin/env bash
# install-skills.sh -- Install this template's workflow skills from the
# in-repo backup (skills/) into the global skill homes, and (re)generate the
# Codex slash-command shims that invoke them.
#
# The template ships FCG *assets* in-repo; the workflow *skills* run from
# global installs and do NOT travel with a folder copy/clone. The repo
# skills/ directory is the SINGLE SOURCE for all workflow skills (inert
# backup -- Claude/Codex never load it directly), and this script deploys it:
#
#   skills/<all>   -> ~/.claude/skills/   (Claude)
#   skills/<all>   -> ~/.codex/skills/    (Codex / GPT) -- FULL PARITY
#   <shim per entry-point cmd + legacy aliases> -> ~/.codex/prompts/  (slash-cmds)
#
# Codex parity (changed 2026-06-15): Codex used to receive only the
# implementation set (build/finding/cycle/handoff) -- Phase-1 planning was
# Claude-only. The user opted GPT into Phase-1 too, so Codex now gets the FULL
# skill set: grill/freeze need to-prd/to-spec/to-issues (freeze orchestrates
# them), and the extra per-skill description cost is negligible. To re-curate,
# replace the Codex install loop with an explicit name list.
#
# Codex slash-command shims (~/.codex/prompts/<cmd>.md) are GENERATED here so
# they never drift when a skill is renamed (the old hand-made fcg-* shims went
# stale pointing at renamed skills: fcg-goal->build, fcg-cycles->cycle,
# fcg-findings->finding). Canonical command name == skill name; the three
# legacy commands are kept as aliases for muscle memory. Other files already in
# ~/.codex/prompts are left untouched. Shims are ALWAYS regenerated (any run).
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
#   CODEX_SKILLS_DIR=/path   bash scripts/install-skills.sh   # custom Codex skills home
#   CODEX_PROMPTS_DIR=/path  bash scripts/install-skills.sh   # custom Codex prompts home
#
# Idempotent; re-run with --force after editing any skill in skills/.
# Slash-command shims are (re)generated on every run, regardless of --force.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/skills"
CLAUDE_DST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_DST="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
CODEX_PROMPTS="${CODEX_PROMPTS_DIR:-$HOME/.codex/prompts}"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

# Entry-point skills that get a Codex slash-command shim (command == skill).
# Sub-skills to-prd/to-spec/to-issues are invoked by freeze, not directly, so
# they install as skills but get no slash command. Trim/extend this list freely.
CODEX_CMDS="grill freeze build finding cycle handoff"

if [ ! -d "$SRC" ]; then
  echo "[FAIL] no source dir: $SRC"
  exit 1
fi

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

install_all() {
  local dst_root="$1"
  mkdir -p "$dst_root"
  installed=0
  for skill_dir in "$SRC"/*/; do
    [ -d "$skill_dir" ] || continue
    install_one "$(basename "$skill_dir")" "$dst_root"
  done
  echo "  ($installed installed/updated)"
}

# Generate one Codex slash-command shim. $1 = command name, $2 = skill name.
gen_shim() {
  local cmd="$1" skill="$2"
  cat > "$CODEX_PROMPTS/$cmd.md" <<EOF
---
description: Run the $skill skill with the supplied arguments.
argument-hint: [request]
---

Use the \`$skill\` skill now.

Pass the slash-command arguments below to the \`$skill\` skill exactly as the user's request. If no arguments were supplied, run \`$skill\` with its default behavior.

Arguments:
\`\$ARGUMENTS\`
EOF
  echo "  + /$cmd -> $skill skill"
}

echo "=== install-skills: repo skills/ -> $CLAUDE_DST (Claude) ==="
install_all "$CLAUDE_DST"
echo

echo "=== install-skills: repo skills/ -> $CODEX_DST (Codex / full parity) ==="
install_all "$CODEX_DST"
echo

echo "=== install-skills: Codex slash-command shims -> $CODEX_PROMPTS ==="
mkdir -p "$CODEX_PROMPTS"
for cmd in $CODEX_CMDS; do
  if [ -d "$SRC/$cmd" ]; then
    gen_shim "$cmd" "$cmd"
  else
    echo "  [WARN] $cmd in CODEX_CMDS but no skills/$cmd -- shim skipped"
  fi
done
# Legacy aliases -> current skills (muscle memory; fix the old stale shims).
gen_shim fcg-goal     build
gen_shim fcg-cycles   cycle
gen_shim fcg-findings finding
echo

cat <<'EOF'
Skills are machine-global: installing once updates EVERY project on this
machine. Repo assets (scripts/, goals/ conventions, dashboard/, ...) are
per-project -- propagate those with scripts/update-workflow.sh instead.

Codex slash-commands are GENERATED from the skill set (never go stale):
  /grill /freeze /build /finding /cycle /handoff   (command == skill)
  /fcg-goal /fcg-cycles /fcg-findings              (legacy aliases -> build/cycle/finding)

Verify:  ls ~/.claude/skills ~/.codex/skills ~/.codex/prompts
Matrix:  see Workflow_Guideline_v1.html (tab 2 "설치 위치" / tab 3 "채널 1")
EOF
