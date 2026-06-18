#!/usr/bin/env bash
# install-skills.sh -- Install this template's workflow skills from the
# in-repo backup (workflows/skills/) into the global skill homes, and (re)generate the
# Codex slash-command shims that invoke them.
#
# The template ships FCG *assets* in-repo; the workflow *skills* run from
# global installs and do NOT travel with a folder copy/clone. The repo
# workflows/skills/ directory is the SINGLE SOURCE for all workflow skills (inert
# backup -- Claude/Codex never load it directly), and this script deploys it:
#
#   workflows/skills/<all>   -> ~/.claude/skills/   (Claude)
#   workflows/skills/<all>   -> ~/.codex/skills/    (Codex / GPT) -- FULL PARITY
#   <shim per entry-point cmd> -> ~/.codex/prompts/  (slash-cmds)
#
# Codex parity (changed 2026-06-15): Codex used to receive only the
# implementation set (build/finding/cycle/handoff) -- Phase-1 planning was
# Claude-only. The user opted GPT into Phase-1 too, so Codex now gets the FULL
# skill set: concept/freeze need to-prd/to-spec/to-issues (freeze orchestrates
# them), and the extra per-skill description cost is negligible. To re-curate,
# replace the Codex install loop with an explicit name list.
#
# Codex slash-command shims (~/.codex/prompts/<cmd>.md) are GENERATED here so
# they never drift when a skill is renamed. Canonical command name == skill
# name. Other files already in ~/.codex/prompts are left untouched, except stale
# names explicitly removed below. Shims are ALWAYS regenerated (any run).
#
# NOTE: several skills carry template-specific fixes (dryforge transplants,
# ladder, EXAMPLE.md pointers). Do NOT reinstall from the public sources
# (mattpocock/skills, greatSumini/cc-system) -- that would overwrite the
# fixes. The repo backup is the source of truth; credits in
# Workflow_Guideline_v1.html (footer).
#
# Usage:
#   bash workflows/scripts/install-skills.sh            # install missing, skip existing
#   bash workflows/scripts/install-skills.sh --force    # overwrite existing (deploy updates)
#   CLAUDE_SKILLS_DIR=/path  bash workflows/scripts/install-skills.sh   # custom Claude home
#   CODEX_SKILLS_DIR=/path   bash workflows/scripts/install-skills.sh   # custom Codex skills home
#   CODEX_PROMPTS_DIR=/path  bash workflows/scripts/install-skills.sh   # custom Codex prompts home
#
# Idempotent; re-run with --force after editing any skill in workflows/skills/.
# Slash-command shims are (re)generated on every run, regardless of --force.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/skills"
CLAUDE_DST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_DST="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
CODEX_PROMPTS="${CODEX_PROMPTS_DIR:-$HOME/.codex/prompts}"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1
BACKUP_ROOT="${COSHERPA_SKILL_BACKUP_DIR:-$HOME/.cosherpa/skill-backups/$(date -u +%Y%m%dT%H%M%SZ)}"

# User-facing skills that get a Codex slash-command shim (command == skill).
# Sub-skills to-prd/to-spec/to-issues are invoked by freeze, not directly, so
# they install as skills but get no slash command. Roadmap is project-local
# under .agents/skills, not a machine-global skill.
CODEX_CMDS="concept freeze build finding cycle handoff prototype spec-sync improve-codebase-architecture"
STALE_SKILLS="grill design"
STALE_PROMPTS="grill design"

if [ ! -d "$SRC" ]; then
  echo "[FAIL] no source dir: $SRC"
  exit 1
fi

backup_existing() {
  local target="$1" label="$2" name="$3"
  [ -e "$target" ] || return 0
  mkdir -p "$BACKUP_ROOT/$label"
  rm -rf "$BACKUP_ROOT/$label/$name"
  cp -R "$target" "$BACKUP_ROOT/$label/$name"
  echo "  * backed up existing $name -> $BACKUP_ROOT/$label/$name"
}

install_one() {
  local name="$1" dst_root="$2" label="$3" target
  target="$dst_root/$name"
  if [ -e "$target" ] && [ "$FORCE" -ne 1 ]; then
    echo "  - $name -- already present (skip; --force to overwrite)"
    return 0
  fi
  if [ -e "$target" ] && [ "$FORCE" -eq 1 ]; then
    backup_existing "$target" "$label" "$name"
  fi
  rm -rf "$target"
  cp -R "$SRC/$name" "$dst_root/"
  echo "  + $name installed -> $target"
  installed=$((installed + 1))
}

install_all() {
  local dst_root="$1" label="$2"
  mkdir -p "$dst_root"
  for stale in $STALE_SKILLS; do
    if [ -e "$dst_root/$stale" ]; then
      backup_existing "$dst_root/$stale" "$label" "$stale.stale"
      rm -rf "$dst_root/$stale"
      echo "  - removed stale renamed skill: $stale"
    fi
  done
  installed=0
  for skill_dir in "$SRC"/*/; do
    [ -d "$skill_dir" ] || continue
    install_one "$(basename "$skill_dir")" "$dst_root" "$label"
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

echo "=== install-skills: workflows/skills/ -> $CLAUDE_DST (Claude) ==="
install_all "$CLAUDE_DST" "claude"
echo

echo "=== install-skills: workflows/skills/ -> $CODEX_DST (Codex / full parity) ==="
install_all "$CODEX_DST" "codex"
echo

echo "=== install-skills: Codex slash-command shims -> $CODEX_PROMPTS ==="
mkdir -p "$CODEX_PROMPTS"
for stale in $STALE_PROMPTS; do
  if [ -e "$CODEX_PROMPTS/$stale.md" ]; then
    backup_existing "$CODEX_PROMPTS/$stale.md" "codex-prompts" "$stale.md.stale"
    rm -f "$CODEX_PROMPTS/$stale.md"
    echo "  - removed stale slash-command shim: /$stale"
  fi
done
for cmd in $CODEX_CMDS; do
  if [ -d "$SRC/$cmd" ]; then
    gen_shim "$cmd" "$cmd"
  else
    echo "  [WARN] $cmd in CODEX_CMDS but no skills/$cmd -- shim skipped"
  fi
done
gen_shim fcg-goal     build
gen_shim fcg-cycles   cycle
gen_shim fcg-findings finding
echo

cat <<'EOF'
Skills are machine-global: installing once updates EVERY project on this
machine. Repo assets (workflows/scripts/, workflows/goals/ conventions,
workflows/dashboard/, ...) are per-project -- propagate those with
workflows/scripts/update-workflow.sh instead.

Codex slash-commands are GENERATED from the skill set (never go stale):
  /concept /freeze /build /finding /cycle /handoff
  /prototype /spec-sync /improve-codebase-architecture
  /fcg-goal /fcg-cycles /fcg-findings                (legacy aliases -> build/cycle/finding)

Verify:  ls ~/.claude/skills ~/.codex/skills ~/.codex/prompts
Backups: overwritten or stale global skills are copied under ~/.cosherpa/skill-backups/
Matrix:  see Workflow_Guideline_v1.html (tab 2 "설치 위치" / tab 3 "채널 1")
EOF
