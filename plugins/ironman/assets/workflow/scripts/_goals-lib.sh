#!/usr/bin/env bash
# _goals-lib.sh -- shared goal-enumeration + state helpers (source-only).
#
# Single source of truth for "what counts as a goal file", the _meta-first
# ordering invariant, the active-goal pointer read, and first-frontmatter-block
# field extraction. Sourced by completion-check.sh, diagnose.sh,
# check-gate-rigor.sh, next-task.sh, update-state.sh. Do NOT re-inline
# `find goals ...` enumeration elsewhere -- copies drift, and the _meta
# ordering is correctness-sensitive (a mis-placed _meta mislabels goal status).
# Functions only; safe to source (no side effects).
#
# Enumeration functions print repo-RELATIVE paths (goals/<name>.md),
# version-sorted, and assume cwd == repo root (every caller does `cd "$ROOT"`).
# Relative paths preserve byte-identical output with the pre-extraction inline
# finds -- do not switch to absolute.

# find_numbered_mds -> numbered goal .md only (goals/<n>-*.md), sort -V.
# `[0-9]*` matches 0-example.md (starts with a digit); excludes _meta.md.
find_numbered_mds() {
  find goals -maxdepth 1 -type f -name '[0-9]*.md' 2>/dev/null | sort -V
}

# find_goal_mds -> numbered goal .md PLUS _meta.md, sort -V.
# The combined list every goal-iterating consumer walks.
find_goal_mds() {
  find goals -maxdepth 1 -type f \( -name '[0-9]*.md' -o -name '_meta.md' \) 2>/dev/null | sort -V
}

# find_goal_artifacts -> goal .md AND .gates.sh (numbered + _meta), sort -V.
# The fingerprint surface for completion-check's rigor-sweep cache.
find_goal_artifacts() {
  find goals -maxdepth 1 -type f \
    \( -name '[0-9]*.md' -o -name '_meta.md' -o -name '[0-9]*.gates.sh' -o -name '_meta.gates.sh' \) \
    2>/dev/null | sort -V
}

# meta_md_path -> goals/_meta.md if present, else empty string.
meta_md_path() {
  find goals -maxdepth 1 -type f -name '_meta.md' 2>/dev/null | head -1
}

# read_active_goal -> contents of .state/active-goal (the pointer
# completion-check.sh writes), or empty if absent. Never errors.
read_active_goal() {
  local f="${ROOT:-$(pwd)}/.state/active-goal"
  [ -f "$f" ] && cat "$f" 2>/dev/null || true
}

# frontmatter_field <file> <key> -> trimmed value of `<key>:` in the FIRST
# frontmatter block (between the first two `---` fences); empty if absent.
# Generic reader for single-line scalar fields (e.g. resolved:, status:).
frontmatter_field() {
  awk -v k="$2" '
    /^---[[:space:]]*$/ { c++; next }
    c==1 && $0 ~ ("^" k ":") { sub("^" k ":[[:space:]]*", ""); print; exit }
  ' "$1" 2>/dev/null
}
