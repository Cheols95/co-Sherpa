#!/usr/bin/env bash
# goals/0-example.next-task.sh -- advisory hint for the example goal.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if bash "$ROOT/goals/0-example.gates.sh" >/dev/null 2>&1; then
  cat <<'MSG'
TASK: Goal 0-example is green.
  - This is a teaching example, not a real goal. The normal path is to
    run build on your issues/PRD (mode B): it converts them into
    goals/<n>-<name>.{md,gates.sh,next-task.sh} and removes this
    0-example triplet as it does so (goals/AGENTS.md bootstrap rule;
    you can also delete it by hand).
  - Run: bash scripts/completion-check.sh
MSG
else
  cat <<'MSG'
TASK: Make goal 0-example green (RED first).
  - Add a #! shebang as line 1 of any runnable scripts/*.sh that lacks one.
  - Re-run: bash goals/0-example.gates.sh
MSG
fi
