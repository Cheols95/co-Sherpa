#!/usr/bin/env bash
# reset-for-new-project.sh -- Clear machine-local / generated state that
# .gitignore cannot strip when this template is distributed by COPYING the
# folder (vs. git clone, which never carries gitignored files). Run this
# once, right after copying the template into a new project directory.
#
# Removes:
#   - workflows-coSherpa/.state/                      FCG runtime: active-goal pointer + gate cache
#   - workflows-coSherpa/.cosherpa/                    plugin sync status + backups
#   - workflows-coSherpa/docs/state/next-task.md      auto-generated; regenerates on first run
#   - workflows-coSherpa/docs/state/progress.md       auto-generated; regenerates on first run
#   - .claude/settings.local.json  the previous owner's machine-local Claude
#                                  settings + permission allowlist
#
# Does NOT touch tracked template content (goals/0-example, _meta, docs
# scaffolding, dashboard). To check for leftover PROJECT content (a prior
# build's PRD / issues / numbered goals), run scripts/template-clean-check.sh.

set -uo pipefail

WORKFLOW_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$WORKFLOW_ROOT/.." && pwd)"
cd "$PROJECT_ROOT"

removed=()
for p in \
  workflows-coSherpa/.state \
  workflows-coSherpa/.cosherpa \
  workflows-coSherpa/docs/state/next-task.md \
  workflows-coSherpa/docs/state/progress.md \
  .claude/settings.local.json \
  .state \
  .cosherpa \
  docs/state/next-task.md \
  docs/state/progress.md \
  .workflow-version
do
  if [ -e "$p" ]; then
    rm -rf "$p"
    removed+=("$p")
  fi
done

if [ "${#removed[@]}" -gt 0 ]; then
  echo "reset-for-new-project: cleared machine-local/runtime state:"
  printf '  %s\n' "${removed[@]}"
else
  echo "reset-for-new-project: nothing to clear (already clean)."
fi

if [ -f .claude/settings.local.json.example ] && [ ! -f .claude/settings.local.json ]; then
  echo
  echo "note: .claude/settings.local.json.example is a tracked starting point."
  echo "      Copy it to .claude/settings.local.json and edit if you want a"
  echo "      project-local Claude permission allowlist."
fi

echo
echo "Next: plan with /concept (Claude), then fill the Architecture"
echo "      and Context sections in AGENTS.md."
