#!/usr/bin/env bash
# Refresh docs/state/* from git + goal status.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

. "$ROOT/scripts/_goals-lib.sh"

STATE="$ROOT/docs/state"
mkdir -p "$STATE"

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
COMMITS=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
LAST=$(git log -1 --pretty='%h %s' 2>/dev/null || echo '(none)')

ACTIVE_GOAL="$(read_active_goal)"
[ -n "$ACTIVE_GOAL" ] || ACTIVE_GOAL="(unknown - run scripts/completion-check.sh)"

{
  echo "# Progress"
  echo ""
  echo "_Last updated: ${NOW}_"
  echo ""
  echo "## Overall"
  echo ""
  echo "- Commits: $COMMITS"
  echo "- Last commit: $LAST"
  echo "- Active goal: $ACTIVE_GOAL"
  echo ""
  echo "## Goal chain"
  echo ""
  echo "| Goal | Gate script | Next-task hint |"
  echo "| --- | --- | --- |"
  for f in $(find_goal_mds); do
    name=$(basename "$f" .md)
    g="goals/${name}.gates.sh"; [ -f "$g" ] && g="ok" || g="missing"
    t="goals/${name}.next-task.sh"; [ -f "$t" ] && t="ok" || t="missing"
    echo "| $name | $g | $t |"
  done
} > "$STATE/progress.md"

{
  echo "# Next Task"
  echo ""
  echo "_Auto-generated $NOW. Do not hand-edit; use blockers.md for overrides._"
  echo ""
  echo '```'
  bash "$ROOT/scripts/next-task.sh"
  echo '```'
} > "$STATE/next-task.md"

[ -f "$STATE/blockers.md" ] || cat > "$STATE/blockers.md" <<'EOF'
# Blockers

_Append-only. Mark resolved with ~~strikethrough~~ rather than deleting._

EOF

[ -f "$STATE/learnings.md" ] || cat > "$STATE/learnings.md" <<'EOF'
# Learnings

_Append-only. One bullet per learning. Keep it terse._

EOF

echo "update-state: refreshed progress.md and next-task.md."
