#!/usr/bin/env bash
# issues-graph-check.sh -- lint the issue dependency graph.
#
#   * dangling: a `depends` id that names no existing issue
#   * cycle:    a circular depends chain (no valid build order exists)
#
# Reuses scripts/_deps-lib.sh (the single depends parser, shared with
# dashboard/engines/roadmap.sh -- no second parser here). roadmap.sh only
# *warns* on dangling and cannot see cycles; this is the hard gate.
#
# Exit 0 = clean (including zero issues). Exit 1 = dangling and/or cycle.
# A cycle or dangling id is a producer-side defect -> stop and fix the issue
# frontmatter, never silently patch. Used as the /freeze pipeline's graph-lint
# stage and surfaced as an advisory by diagnose.sh.
#
# Usage:
#   issues-graph-check.sh              # lint $ISSUES_DIR (default docs/issues)
#   ISSUES_DIR=path issues-graph-check.sh
#   issues-graph-check.sh --self-test  # run built-in cases

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/_deps-lib.sh"

declare -A ADJ ISSET COLOR
CYCLE_HIT=0
CYCLE_EDGE=""

# depth-first search with three-coloring; a gray (on-stack) target = back-edge = cycle.
_dfs() {
  local u="$1" v
  COLOR[$u]=1
  for v in ${ADJ[$u]:-}; do
    [ -z "${ISSET[$v]:-}" ] && continue   # dangling target is not a real node
    case "${COLOR[$v]:-0}" in
      1) CYCLE_HIT=1; CYCLE_EDGE="$u -> $v"; return ;;
      0) _dfs "$v"; [ "$CYCLE_HIT" = 1 ] && return ;;
    esac
  done
  COLOR[$u]=2
}

# check_dir <dir> -> prints a report, returns 0 (clean) or 1 (defect).
check_dir() {
  local dir="$1" ids="" id deps f d n=0 edges=0 dangling="" rc=0
  ADJ=(); ISSET=(); COLOR=(); CYCLE_HIT=0; CYCLE_EDGE=""

  if [ ! -d "$dir" ]; then
    echo "issues-graph-check: no such dir: $dir (OK -- nothing to lint)"
    return 0
  fi

  while IFS= read -r f; do
    [ -z "$f" ] && continue
    id="$(issue_id_for "$f")"
    ISSET[$id]=1
    ids="$ids $id"
    n=$((n + 1))
  done <<EOF
$(find "$dir" -maxdepth 1 -type f -name '[0-9]*.md' 2>/dev/null | sort -V)
EOF

  if [ "$n" -eq 0 ]; then
    echo "issues-graph-check: 0 issues in $dir -- nothing to lint (OK)"
    return 0
  fi

  for id in $ids; do
    f="$(find "$dir" -maxdepth 1 -type f -name "${id}-*.md" 2>/dev/null | head -1)"
    [ -z "$f" ] && f="$(find "$dir" -maxdepth 1 -type f -name "${id}.md" 2>/dev/null | head -1)"
    deps="$(parse_issue_deps "$f" "$id")"
    ADJ[$id]="$deps"
    for d in $deps; do
      edges=$((edges + 1))
      if [ -z "${ISSET[$d]:-}" ]; then
        dangling="${dangling}  ${id} -> ${d} (no such issue)"$'\n'
      fi
    done
  done

  for id in $ids; do
    [ "${COLOR[$id]:-0}" = 0 ] && _dfs "$id"
    [ "$CYCLE_HIT" = 1 ] && break
  done

  if [ -n "$dangling" ]; then
    echo "issues-graph-check: DANGLING depends (fix the frontmatter):"
    printf '%s' "$dangling"
    rc=1
  fi
  if [ "$CYCLE_HIT" = 1 ]; then
    echo "issues-graph-check: CYCLE in depends graph (back-edge: $CYCLE_EDGE) -- no valid build order"
    rc=1
  fi
  [ "$rc" = 0 ] && echo "issues-graph-check: OK -- $n issues, $edges depends edges, acyclic, no dangling"
  return $rc
}

self_test() {
  local tmp rc=0
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  mkdir -p "$tmp/clean"
  printf -- '---\ndepends: []\n---\n# a\n'    > "$tmp/clean/001-a.md"
  printf -- '---\ndepends: [001]\n---\n# b\n' > "$tmp/clean/002-b.md"
  printf -- '---\ndepends: [002]\n---\n# c\n' > "$tmp/clean/003-c.md"
  if check_dir "$tmp/clean" >/dev/null; then echo "  [PASS] clean chain -> exit 0"; else echo "  [FAIL] clean chain expected 0"; rc=1; fi

  mkdir -p "$tmp/cyc"
  printf -- '---\ndepends: [002]\n---\n# a\n' > "$tmp/cyc/001-a.md"
  printf -- '---\ndepends: [001]\n---\n# b\n' > "$tmp/cyc/002-b.md"
  if check_dir "$tmp/cyc" >/dev/null; then echo "  [FAIL] cycle expected 1"; rc=1; else echo "  [PASS] cycle -> exit 1"; fi

  mkdir -p "$tmp/self"
  printf -- '---\ndepends: [001]\n---\n# a\n' > "$tmp/self/001-a.md"
  if check_dir "$tmp/self" >/dev/null; then echo "  [PASS] self-dep excluded -> exit 0"; else echo "  [FAIL] self-dep expected 0"; rc=1; fi

  mkdir -p "$tmp/dang"
  printf -- '---\ndepends: [099]\n---\n# a\n' > "$tmp/dang/001-a.md"
  if check_dir "$tmp/dang" >/dev/null; then echo "  [FAIL] dangling expected 1"; rc=1; else echo "  [PASS] dangling -> exit 1"; fi

  mkdir -p "$tmp/prose"
  printf -- '# a\n'                       > "$tmp/prose/001-a.md"
  printf -- '# b\n\n## Blocked by\n- 001\n' > "$tmp/prose/002-b.md"
  if check_dir "$tmp/prose" >/dev/null; then echo "  [PASS] prose-fallback clean -> exit 0"; else echo "  [FAIL] prose expected 0"; rc=1; fi

  mkdir -p "$tmp/empty"
  if check_dir "$tmp/empty" >/dev/null; then echo "  [PASS] empty dir -> exit 0"; else echo "  [FAIL] empty expected 0"; rc=1; fi

  [ "$rc" = 0 ] && echo "issues-graph-check self-test: ALL PASS" || echo "issues-graph-check self-test: FAILURES"
  return $rc
}

case "${1:-}" in
  --self-test) echo "issues-graph-check self-test:"; self_test ;;
  *)           check_dir "${ISSUES_DIR:-$ROOT/docs/issues}" ;;
esac
