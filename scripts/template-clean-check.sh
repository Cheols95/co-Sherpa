#!/usr/bin/env bash
# Report whether this template has been cleaned after a project build.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

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
mapfile -t prd_leftovers < <(find docs/prd -maxdepth 1 -type f ! -name 'README.md' 2>/dev/null | sort)
mapfile -t issue_leftovers < <(find docs/issues -maxdepth 1 -type f ! -name 'README.md' 2>/dev/null | sort)
mapfile -t goal_leftovers < <(
  find goals -maxdepth 1 -type f 2>/dev/null |
    sed 's#.*/##' |
    grep -Ev '^(AGENTS\.md|0-example\.(md|gates\.sh|next-task\.sh)|_meta\.(md|gates\.sh|next-task\.sh))$' |
    sort |
    sed 's#^#goals/#'
)

report_dirty "docs/prd contains project PRD files" "${prd_leftovers[@]}"
report_dirty "docs/issues contains project issue files" "${issue_leftovers[@]}"
report_dirty "goals contains project goal files" "${goal_leftovers[@]}"

required=(
  dashboard/engines/roadmap.sh
  dashboard/engines/roadmap-selftest.sh
  dashboard/README.md
  .claude/skills/roadmap
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
leaked=()
for p in .state docs/state/next-task.md docs/state/progress.md .claude/settings.local.json; do
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
