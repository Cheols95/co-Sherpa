#!/usr/bin/env bash
# _deps-lib.sh -- shared dependency parsing for issue files.
#
# Single source of truth for `depends` extraction. Sourced by BOTH
# dashboard/engines/roadmap.sh (dashboard render) and
# scripts/issues-graph-check.sh (lint gate). Do NOT add a second parser
# anywhere -- two parsers drift. This file defines functions only; it is
# safe to source (no side effects).

# issue_id_for <file> -> the leading id from the filename stem (NNN-slug.md -> NNN).
issue_id_for() {
  local base
  base="$(basename "$1" .md)"
  printf '%s' "${base%%-*}"
}

# parse_issue_deps <file> <self_id> -> space-separated, sorted, de-duped blocking
# ids (3-digit). Frontmatter `depends: [NNN, ...]` (inline list, first frontmatter
# block) is the machine-readable contract and wins; the prose "## Blocked by"
# section is the human-readable fallback for issues authored before the frontmatter
# convention. `tr '\n' ' '` flattens multi-id blocks to one line so the value can
# enter a pipe-delimited record without a newline splitting it on read-back
# (finding 2026-06-06T0100). Downstream `for d in $deps` handles space separation.
parse_issue_deps() {
  local f="$1" id="$2" deps
  deps="$(awk '/^---[[:space:]]*$/{c++; next} c==1 && /^depends:/{sub(/^depends:[[:space:]]*/,""); print; exit}' "$f" 2>/dev/null |
    grep -oE '\b[0-9]{3}\b' | sort -u | grep -v "^$id$" | tr '\n' ' ' || true)"
  if [ -z "$deps" ]; then
    deps="$(awk 'tolower($0) ~ /^##[[:space:]]+blocked by/{flag=1; next} /^##[[:space:]]/{if(flag) exit} flag' "$f" 2>/dev/null |
      grep -oE '\b[0-9]{3}\b' | sort -u | grep -v "^$id$" | tr '\n' ' ' || true)"
  fi
  printf '%s' "$deps"
}
