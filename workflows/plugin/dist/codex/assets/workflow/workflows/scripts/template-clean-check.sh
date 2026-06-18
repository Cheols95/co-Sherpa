#!/usr/bin/env bash
# Report whether this template has been cleaned after a project build.

set -uo pipefail

WORKFLOW_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$WORKFLOW_ROOT/.." && pwd)"
cd "$WORKFLOW_ROOT"

. "$WORKFLOW_ROOT/scripts/_portable.sh"

PASS=true

report_dirty() {
  local label="$1"
  shift
  if [ "$#" -gt 0 ]; then
    echo "$label:"
    printf '  %s\n' "$@"
    PASS=false
  fi
}

if [ -f dashboard/engines/roadmap-selftest.sh ]; then
  if ! bash dashboard/engines/roadmap-selftest.sh >/dev/null 2>&1; then
    echo "dashboard/engines/roadmap-selftest.sh failed"
    PASS=false
  fi
else
  echo "missing dashboard/engines/roadmap-selftest.sh"
  PASS=false
fi

# Portable find (no GNU-only -printf): plain output is the path; strip to
# basename with sed where a basename is needed. -printf errors on BSD/
# macOS and, with 2>/dev/null, would silently yield empty arrays -> a
# DIRTY template falsely reporting "clean".
prd_leftovers=()
while IFS= read -r item; do
  [ -n "$item" ] && prd_leftovers+=("$item")
done < <(find docs/prd -maxdepth 1 -type f ! -name 'README.md' 2>/dev/null | sort)

issue_leftovers=()
while IFS= read -r item; do
  [ -n "$item" ] && issue_leftovers+=("$item")
done < <(find docs/issues -maxdepth 1 -type f ! -name 'README.md' 2>/dev/null | sort)

concept_leftovers=()
while IFS= read -r item; do
  [ -n "$item" ] && concept_leftovers+=("$item")
done < <(
  find docs/design -maxdepth 1 -type f 2>/dev/null |
    sed 's#.*/##' |
    grep -Ev '^(AGENTS\.md|CLAUDE\.md|README\.md)$' |
    sort |
    sed 's#^#docs/design/#'
)

goal_leftovers=()
while IFS= read -r item; do
  [ -n "$item" ] && goal_leftovers+=("$item")
done < <(
  find goals -maxdepth 1 -type f 2>/dev/null |
    sed 's#.*/##' |
    grep -Ev '^(AGENTS\.md|CLAUDE\.md|EXAMPLE\.md|0-example\.(md|gates\.sh|next-task\.sh)|_meta\.(md|gates\.sh|next-task\.sh))$' |
    sort |
    sed 's#^#goals/#'
)

report_dirty "docs/prd contains project PRD files" "${prd_leftovers[@]}"
report_dirty "docs/issues contains project issue files" "${issue_leftovers[@]}"
report_dirty "docs/design contains project checklist files" "${concept_leftovers[@]}"
report_dirty "goals contains project goal files" "${goal_leftovers[@]}"

required=(
  dashboard/engines/roadmap.sh
  dashboard/engines/roadmap-selftest.sh
  dashboard/README.md
  "$PROJECT_ROOT/.claude/skills/roadmap"
  "$PROJECT_ROOT/.agents/skills/roadmap"
)
for path in "${required[@]}"; do
  if [ ! -e "$path" ]; then
    echo "missing required dashboard artifact: $path"
    PASS=false
  fi
done

for stale in scripts/roadmap.sh docs/state/roadmap.html; do
  if [ -e "$stale" ]; then
    echo "stale generated or moved file remains: $stale"
    PASS=false
  fi
done

# Machine-local / runtime state that .gitignore cannot strip on a folder
# copy (vs git clone). A copy-ready template must not carry these; they
# regenerate on first run. Clear with scripts/reset-for-new-project.sh.
# workflows/.ironman/workflow-version belongs to PROJECT copies (template-SHA reconcile marker,
# written by workflows/scripts/update-workflow.sh) -- the template itself must not
# carry one, or every copied project starts with a bogus baseline.
leaked=()
for p in \
  .state \
  .ironman \
  .ironman/workflow-version \
  docs/state/next-task.md \
  docs/state/progress.md \
  "$PROJECT_ROOT/.claude/settings.local.json" \
  "$PROJECT_ROOT/.workflow-version" \
  "$PROJECT_ROOT/.state" \
  "$PROJECT_ROOT/.ironman" \
  "$PROJECT_ROOT/docs/state/next-task.md" \
  "$PROJECT_ROOT/docs/state/progress.md"
do
  [ -e "$p" ] && leaked+=("$p")
done
if [ "${#leaked[@]}" -gt 0 ]; then
  echo "machine-local/runtime state present (run scripts/reset-for-new-project.sh before copy):"
  printf '  %s\n' "${leaked[@]}"
  PASS=false
fi

if [ "$PASS" = true ]; then
  echo "template-clean-check: clean"
  exit 0
fi

echo "template-clean-check: dirty template state remains"
exit 1
