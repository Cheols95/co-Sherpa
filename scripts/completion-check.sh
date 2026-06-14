#!/usr/bin/env bash
# completion-check.sh — Parallel orchestrator for all goal gate suites.
#
# Discovers every goals/<n>-<name>.md, launches each matching
# <n>-<name>.gates.sh as a background worker (bounded by
# $GATES_CONCURRENCY, default 4), then aggregates per-goal stdout in
# numeric order. Writes the first numerically-failing goal's path to
# .state/active-goal so diagnose.sh / next-task.sh route correctly. Exit
# 0 only when every gate of every goal passes.
#
# This script is the only owner of the "no prior-goal regression"
# semantics: per-goal scripts do not chain into earlier goals. Running a
# single `bash goals/<n>-*.gates.sh` checks that goal's surface only —
# run this orchestrator for the full chain.
#
# Env:
#   GATES_CONCURRENCY  default 4; cap on parallel workers (0 → serial)
#   GATES_SKIP_DEEP    default 1 (skip external-system gates like Docker
#                      spin-up, deploy state). Set to 0 explicitly to run
#                      the full world-state suite (release check / job).
#   GATES_NO_CACHE     propagated to workers; bypasses the gate cache
#   GATES_SKIP_META    skip the cross-cutting goals/_meta gate suite (CI
#                      often runs lint/typecheck/test/build as explicit
#                      steps, so it sets this to avoid duplicating work)

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p "$ROOT/.state"
ACTIVE_FILE="$ROOT/.state/active-goal"

# Portable sha256 for the rigor-cache fingerprint: reuse the single detection
# in _gate-cache.sh (source-only helper) instead of duplicating it. It exports
# $_GATE_CACHE_SHA_CMD (the external sha command, or "" if none is available).
. "$ROOT/scripts/_gate-cache.sh"

CONCURRENCY="${GATES_CONCURRENCY:-4}"
case "$CONCURRENCY" in
  ''|*[!0-9]*) CONCURRENCY=4 ;;   # non-numeric → documented default (4), not 2
  0) CONCURRENCY=1 ;;
esac

# Default to skipping external-system gates. The chain is meant to verify
# the *code contract* deterministically; deploy/Docker state is checked by
# a separate cadence. Callers that need full world verification (release
# checklists, a scheduled job) override with GATES_SKIP_DEEP=0.
export GATES_SKIP_DEEP="${GATES_SKIP_DEEP:-1}"

GOALS=()
META_MD=""
while IFS= read -r f; do
  if [ "$(basename "$f")" = "_meta.md" ]; then
    META_MD="$f"
  else
    GOALS+=("$f")
  fi
done < <(find goals -maxdepth 1 -type f \( -name '[0-9]*.md' -o -name '_meta.md' \) 2>/dev/null | sort -V)

# Numbered-goal count BEFORE _meta is folded in below. A stack of only
# _meta (zero numbered goals) is NOT "done": _meta passes vacuously on a
# fresh template, which would otherwise mint a false ALL_DONE. The L80
# empty-guard tests the COMBINED array, so it never fires once _meta is
# present — this count is the real guard (see below).
NUM_NUMBERED=${#GOALS[@]}

# Meta is launched first so its slot in the parallel pool starts at t=0.
# When GATES_CONCURRENCY is low and _meta dominates wall-clock (lint+tsc+
# test+builds), this overlaps meta work with the lightest numeric goals
# instead of leaving meta as a serial tail.
#
# CI workflows that already run lint/typecheck/test/build as explicit
# steps (for per-step visibility in the Actions UI) set GATES_SKIP_META=1
# to avoid duplicating that work here. The meta claims are still enforced
# — by the workflow itself.
if [ -n "$META_MD" ] && [ "${GATES_SKIP_META:-}" != "1" ]; then
  GOALS=("$META_MD" "${GOALS[@]}")
fi

# False-completion guard. With zero numbered goals but a _meta present,
# the chain would otherwise pass vacuously and write ALL_DONE — an
# autonomous agent would believe a build with nothing in it is finished.
# ASCII-only message (no glyphs) so a cp949 re-save can't corrupt it.
if [ "$NUM_NUMBERED" -eq 0 ] && [ -n "$META_MD" ]; then
  echo "[completion-check] No numbered goal authored yet (only _meta)."
  echo "  _meta passes vacuously on a fresh template, so this is NOT done."
  echo "  Convert your spec into the first goal: run build on"
  echo "  docs/issues/*.md (or docs/prd/PRD.md). Mode B writes"
  echo "  goals/<n>-<name>.{md,gates.sh,next-task.sh} and replaces the"
  echo "  goals/0-example.* placeholder."
  echo "NEEDS_FIRST_GOAL" > "$ACTIVE_FILE"
  exit 1
fi

if [ "${#GOALS[@]}" -eq 0 ]; then
  echo "✗ completion-check: no goals/*.md found."
  echo "(none)" > "$ACTIVE_FILE"
  exit 1
fi

STAGE_DIR=$(mktemp -d)
trap 'rm -rf "$STAGE_DIR"' EXIT

# Parallel arrays indexed by goal position.
GOAL_NAMES=()
GOAL_OUT_FILES=()
GOAL_PIDS=()
GOAL_LAUNCH_FAILED=()

launch_goal() {
  local idx="$1"
  local goal_md="$2"
  local goal_name
  goal_name=$(basename "$goal_md" .md)
  local gate_script="goals/${goal_name}.gates.sh"
  local out_file="$STAGE_DIR/${goal_name}.out"

  GOAL_NAMES[$idx]="$goal_name"
  GOAL_OUT_FILES[$idx]="$out_file"

  if [ ! -f "$gate_script" ] && [ ! -x "$gate_script" ]; then
    printf '✗ missing gate script: %s\n' "$gate_script" > "$out_file"
    GOAL_PIDS[$idx]=0
    GOAL_LAUNCH_FAILED[$idx]=1
    return
  fi

  GOAL_LAUNCH_FAILED[$idx]=0
  bash "$gate_script" >"$out_file" 2>&1 &
  GOAL_PIDS[$idx]=$!
  printf '▷ %s (pid %s)\n' "$goal_name" "${GOAL_PIDS[$idx]}"
}

wait_for_slot() {
  while :; do
    local running
    running=$(jobs -rp 2>/dev/null | wc -l | tr -d ' ')
    if [ "$running" -lt "$CONCURRENCY" ]; then
      return 0
    fi
    sleep 0.2
  done
}

echo "=== COMPLETION CHECK (parallel, concurrency=$CONCURRENCY) ==="
echo

OVERALL_PASS=true
FIRST_FAIL_MD=""
FAILED=()

# Meta: orchestrator-owned rigor sweep. Closes the leak where a prior
# goal's .md is not in its own GATE_INPUTS — direct edits to those .md
# files would otherwise sit behind a stale cache. Cheap, runs before the
# parallel goal workers so doc/gate drift fails fast.
echo "--- Meta: gate rigor sweep (every .md ↔ .gates.sh) ---"

RIGOR_CACHE_DIR="$ROOT/.state/gate-cache"
RIGOR_CACHE_FILE="$RIGOR_CACHE_DIR/_meta-rigor"

rigor_inputs() {
  find goals -maxdepth 1 -type f \
    \( -name '[0-9]*.md' -o -name '_meta.md' -o -name '[0-9]*.gates.sh' -o -name '_meta.gates.sh' \) \
    2>/dev/null | sort -V
}

rigor_fingerprint() {
  local files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(rigor_inputs)
  if [ "${#files[@]}" -eq 0 ]; then
    echo ""
    return
  fi
  [ -n "$_GATE_CACHE_SHA_CMD" ] || { echo ""; return; }
  cat "${files[@]}" 2>/dev/null | $_GATE_CACHE_SHA_CMD 2>/dev/null | awk '{print $1}'
}

rigor_cache_fresh() {
  [ -f "$RIGOR_CACHE_FILE" ] || return 1
  local cached current
  cached=$(cat "$RIGOR_CACHE_FILE" 2>/dev/null || true)
  current=$(rigor_fingerprint)
  [ -n "$cached" ] && [ "$cached" = "$current" ] || return 1
  # Defensive: cache file mtime must be newer than every input.
  while IFS= read -r f; do
    if [ "$f" -nt "$RIGOR_CACHE_FILE" ]; then
      return 1
    fi
  done < <(rigor_inputs)
  return 0
}

if ! bash "$ROOT/scripts/check-gate-rigor.sh" --self-test >/dev/null 2>&1; then
  echo "    ✗ rigor self-test failed — UNIVERSAL_RE may be broken"
  OVERALL_PASS=false
fi

if rigor_cache_fresh; then
  echo "    ✓ cache hit — rigor sweep skipped (fingerprint unchanged)"
else
  if bash "$ROOT/scripts/check-gate-rigor.sh" --all; then
    echo "    ✓ every goal's universal claims match an iterating gate"
    mkdir -p "$RIGOR_CACHE_DIR"
    rigor_fingerprint > "$RIGOR_CACHE_FILE"
  else
    echo "    ✗ rigor mismatch — fix .md or its gate before continuing"
    OVERALL_PASS=false
    # Collect ALL rigor-failing goals; do not pick a winner here. The
    # active-goal pointer is chosen after the runtime sweep (below) so a
    # higher-numbered goal's rigor failure can't mask a lower-numbered
    # goal's runtime failure.
    while IFS= read -r md; do
      if ! bash "$ROOT/scripts/check-gate-rigor.sh" "$md" >/dev/null 2>&1; then
        FAILED+=("$md")
      fi
    done < <(find goals -maxdepth 1 -type f \( -name '[0-9]*.md' -o -name '_meta.md' \) | sort -V)
  fi
fi
echo

idx=0
for goal_md in "${GOALS[@]}"; do
  wait_for_slot
  launch_goal "$idx" "$goal_md"
  idx=$((idx + 1))
done

echo
echo "--- collecting results ---"
echo

idx=0
for goal_md in "${GOALS[@]}"; do
  pid="${GOAL_PIDS[$idx]}"
  goal_name="${GOAL_NAMES[$idx]}"
  out_file="${GOAL_OUT_FILES[$idx]}"
  launch_failed="${GOAL_LAUNCH_FAILED[$idx]}"

  if [ "$launch_failed" = "1" ]; then
    goal_exit=1
  else
    if wait "$pid"; then
      goal_exit=0
    else
      goal_exit=$?
    fi
  fi

  echo "--- Goal: $goal_name ($goal_md) ---"
  if [ -f "$out_file" ]; then
    cat "$out_file"
  fi
  if [ "$goal_exit" -eq 0 ]; then
    printf '    ✓ goal %s passes all gates.\n' "$goal_name"
  else
    printf '    ✗ goal %s has failing gates.\n' "$goal_name"
    OVERALL_PASS=false
    FAILED+=("$goal_md")
  fi
  printf '\n'

  idx=$((idx + 1))
done

# Active goal = the lowest-numbered failing goal across BOTH the rigor
# sweep and the runtime suites (the docstring contract). _meta is
# cross-cutting and is checked first, so it wins when it is among the
# failures; otherwise the numerically-lowest goal wins (_meta sorts last
# under -V, so the explicit check is required).
if [ "${#FAILED[@]}" -gt 0 ]; then
  FIRST_FAIL_MD=""
  for cand in "${FAILED[@]}"; do
    if [ "$(basename "$cand")" = "_meta.md" ]; then
      FIRST_FAIL_MD="$cand"
      break
    fi
  done
  if [ -z "$FIRST_FAIL_MD" ]; then
    FIRST_FAIL_MD=$(printf '%s\n' "${FAILED[@]}" | sort -V | head -1)
  fi
fi

# Defensive: if something set OVERALL_PASS=false without populating FAILED
# (e.g. the rigor self-test failed — neither sweep), still write a
# non-empty pointer so downstream readers don't see a blank active-goal.
if [ "$OVERALL_PASS" != true ] && [ -z "$FIRST_FAIL_MD" ]; then
  if [ -n "$META_MD" ]; then
    FIRST_FAIL_MD="$META_MD"
  else
    FIRST_FAIL_MD=$(find goals -maxdepth 1 -type f -name '[0-9]*.md' 2>/dev/null | sort -V | head -1)
  fi
fi

if [ "$OVERALL_PASS" = true ]; then
  echo "ALL_DONE" > "$ACTIVE_FILE"
  echo "🎉 ALL GOALS ACHIEVED. Every gate of every goal passes."
  # Cycle-end doc-sync advisory (never gates): the chain just went green,
  # which is the cheapest moment to reconcile the contract docs with the
  # code before drift compounds. ASCII-only message.
  if [ -f docs/spec/INDEX.md ]; then
    echo "  advisory: chain is green -- run /spec-sync once to reconcile docs/spec/ with the code (Phase 2.5 cadence)."
  fi
  exit 0
fi

echo "$FIRST_FAIL_MD" > "$ACTIVE_FILE"
echo "⚠ Active goal: $(cat "$ACTIVE_FILE")"
echo "  Continue iterating against that goal."
exit 1
