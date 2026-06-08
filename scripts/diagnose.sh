#!/usr/bin/env bash
# diagnose.sh — Tell the agent what state the repo is in. Read-only,
# idempotent, stack-neutral. Run this first, every iteration.
#
# Project-specific signals (test matrix, coverage, scaffolding presence)
# are intentionally omitted from this generic version — add your own
# sections below the "Project signals" marker if useful.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== DEVELOPMENT STATE ==="
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

echo "=== Iteration / Commits ==="
if git rev-parse --git-dir >/dev/null 2>&1; then
  COMMITS=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
  echo "Total commits: $COMMITS"
  echo ""
  echo "Last 10:"
  git log --oneline -10 2>/dev/null || echo "  (no commits yet)"
else
  echo "  (not a git repo)"
fi
echo ""

echo "=== Active Goal ==="
ACTIVE_FILE="$ROOT/.state/active-goal"
ptr=""
[ -f "$ACTIVE_FILE" ] && ptr=$(cat "$ACTIVE_FILE" 2>/dev/null || true)

if [ -n "$ptr" ]; then
  echo "  $ptr"
else
  echo "  (unknown — run scripts/completion-check.sh first)"
fi

# A pointer only certifies goal status when it is ALL_DONE or an existing
# goal file. Empty / (none) / NEEDS_FIRST_GOAL / a deleted path means the
# chain was never successfully checked — show every goal as "(not yet
# checked)" rather than falsely green.
verified=false
if [ "$ptr" = "ALL_DONE" ] || { [ -n "$ptr" ] && [ -f "$ptr" ]; }; then
  verified=true
fi

if [ -d goals ]; then
  echo "  All goals:"
  # Mirror completion-check.sh run order: _meta is launched first, so it
  # must lead the display too. Raw sort -V pushes _meta last, which would
  # mislabel it "(deferred)" or hide a _meta failure behind green numbers.
  goal_list=()
  meta_md=""
  while IFS= read -r f; do
    if [ "$(basename "$f")" = "_meta.md" ]; then
      meta_md="$f"
    else
      goal_list+=("$f")
    fi
  done < <(find goals -maxdepth 1 -type f \( -name '[0-9]*.md' -o -name '_meta.md' \) 2>/dev/null | sort -V)
  [ -n "$meta_md" ] && goal_list=("$meta_md" ${goal_list[@]+"${goal_list[@]}"})

  seen_active=false
  for f in ${goal_list[@]+"${goal_list[@]}"}; do
    name=$(basename "$f" .md)
    gate="goals/${name}.gates.sh"
    if [ ! -f "$gate" ]; then
      echo "    - $f (no gate script)"
      continue
    fi
    if [ "$verified" = false ]; then
      status="(not yet checked)"
    elif [ "$ptr" = "ALL_DONE" ]; then
      status="✓ passed (as of last check)"
    elif [ "$ptr" = "$f" ]; then
      status="⚙ active (failing)"
      seen_active=true
    elif [ "$seen_active" = false ]; then
      status="✓ passed (as of last check)"
    else
      status="(deferred — earlier goal is active)"
    fi
    echo "    - $f $status"
  done
fi
echo ""

echo "=== Open Findings (docs/findings/) ==="
if [ -d docs/findings ]; then
  OPEN=0
  for f in $(find docs/findings -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort); do
    base=$(basename "$f")
    case "$base" in AGENTS.md|README.md|CLAUDE.md|EXAMPLE.md) continue ;; esac
    # Read the `resolved:` field from the first frontmatter block.
    res=$(awk '/^---[[:space:]]*$/{c++; next} c==1 && /^resolved:/{sub(/^resolved:[[:space:]]*/,""); print; exit}' "$f")
    case "$res" in
      true) : ;;
      *) OPEN=$((OPEN+1)); echo "    - $base (resolved: ${res:-?})" ;;
    esac
  done
  [ "$OPEN" -eq 0 ] && echo "    (none open)"
else
  echo "    (no docs/findings/ directory)"
fi
echo ""

# ─── Project signals (add stack-specific sections here) ─────────────────
# Examples you might add:
#   - test pass/fail summary from your runner
#   - enumeration coverage of a source of truth (models / routes / specs)
#   - scaffolding presence checks
# Keep it read-only.

echo "=== Blockers ==="
# Filter comment headers, blank lines, and the italic boilerplate the
# template seeds (e.g. "_Append-only..._") so guidance never prints as a
# real blocker. Decide emptiness AFTER filtering.
real_blockers=""
[ -f docs/state/blockers.md ] && real_blockers=$(grep -vE '^#|^[[:space:]]*$|^_Append-only' docs/state/blockers.md 2>/dev/null || true)
if [ -n "$real_blockers" ]; then
  printf '%s\n' "$real_blockers" | head -10 | sed 's/^/  /'
else
  echo "  (none)"
fi
echo ""

echo "=== Uncommitted Changes ==="
git status --short 2>/dev/null | head -20 | sed 's/^/  /' || echo "  (clean)"
echo ""

echo "=== Recommended Next Action ==="
bash "$ROOT/scripts/next-task.sh"
