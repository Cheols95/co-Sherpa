#!/usr/bin/env bash
# update-workflow.sh -- Pull workflow-harness updates from the template repo
# into THIS project. Run from the PROJECT root.
#
# The template repo is the single source for harness files (the list lives
# in the template's workflows-coSherpa/workflow-manifest.txt, read at the template's HEAD --
# committed state only; uncommitted template edits never propagate).
# Project content (workflows-coSherpa/docs bodies, numbered goals, cycles history, CONTEXT.md,
# workflows-coSherpa/docs/state/*, scripts/smoke.sh) is NEVER touched.
#
# 3-way logic, keyed on the workflows-coSherpa/.cosherpa/workflow-version marker (template SHA this
# project last reconciled with):
#   local == template                       -> [OK]        in sync
#   local missing, not in base              -> [NEW]       create on --apply
#   local missing, was in base              -> [LOCAL-DEL] intentional delete, kept
#   local == base, template changed         -> [UPDATE]    overwrite on --apply
#   local changed, template == base         -> [LOCAL-MOD] project customization, kept
#   both changed                            -> [CONFLICT]  report only; reconcile by hand
#   no marker yet, local != template        -> [REVIEW]    first run; report only
#
# Usage (from the project root):
#   bash workflows-coSherpa/scripts/update-workflow.sh --from <template-path-or-git-url>   # dry-run report
#   bash workflows-coSherpa/scripts/update-workflow.sh --apply                             # apply NEW+UPDATE
#   bash workflows-coSherpa/scripts/update-workflow.sh --set-baseline                      # mark reconciled
#   flags: --force-dirty (skip clean-tree guard)   env: WORKFLOW_TEMPLATE_DIR
#
# First run on an old project (no marker, script not present yet):
#   cd <project> && bash <template>/workflows-coSherpa/scripts/update-workflow.sh --from <template>
# After resolving any [REVIEW]/[CONFLICT] items, run --set-baseline once;
# from then on updates are 3-way automatic.
#
# The marker source= line remembers --from, so later runs need no arguments.
# Exit codes: 0 = nothing pending; 1 = CONFLICT/REVIEW items need a human;
#             2 = usage/environment error.

set -uo pipefail

usage() {
  sed -n '2,38p' "$0" | sed 's/^# \{0,1\}//'
}

ROOT="$(pwd)"
MARKER="$ROOT/workflows-coSherpa/.cosherpa/workflow-version"
if [ -f "$ROOT/workflows-coSherpa/scripts/_portable.sh" ]; then
  . "$ROOT/workflows-coSherpa/scripts/_portable.sh"
fi

FROM="" APPLY=0 SETBASE=0 FORCE_DIRTY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --from)        FROM="${2:-}"; shift 2 ;;
    --apply)       APPLY=1; shift ;;
    --set-baseline) SETBASE=1; shift ;;
    --force-dirty) FORCE_DIRTY=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "[FAIL] unknown argument: $1"; usage; exit 2 ;;
  esac
done

# -- project-root guard ------------------------------------------------------
if [ ! -f "$ROOT/AGENTS.md" ] && [ ! -d "$ROOT/workflows-coSherpa/goals" ]; then
  echo "[FAIL] run from the project root (no AGENTS.md / workflows-coSherpa/goals/ here): $ROOT"
  exit 2
fi

# -- read marker --------------------------------------------------------------
BASE_SHA="" MARKER_SRC=""
if [ -f "$MARKER" ]; then
  BASE_SHA=$(sed -n 's/^sha=//p' "$MARKER" | head -1)
  MARKER_SRC=$(sed -n 's/^source=//p' "$MARKER" | head -1)
fi

# -- resolve template source ---------------------------------------------------
SRC="${FROM:-${MARKER_SRC:-${WORKFLOW_TEMPLATE_DIR:-}}}"
if [ -z "$SRC" ]; then
  echo "[FAIL] no template source. Pass --from <path|git-url> (it is remembered in workflows-coSherpa/.cosherpa/workflow-version)."
  exit 2
fi
SRC="${SRC//\\//}"   # tolerate Windows backslash paths

CLEANUP=""
if [ -d "$SRC" ]; then
  TPL="$SRC"
else
  if command -v portable_mktemp_dir >/dev/null 2>&1; then
    TPL=$(portable_mktemp_dir) || exit 2
  else
    TPL=$(mktemp -d 2>/dev/null || mktemp -d "${TMPDIR:-/tmp}/cosherpa.XXXXXX") || exit 2
  fi
  CLEANUP="$TPL"
  echo "[..] cloning template: $SRC"
  if ! git clone --quiet "$SRC" "$TPL"; then
    echo "[FAIL] clone failed: $SRC"; exit 2
  fi
fi
trap '[ -n "$CLEANUP" ] && rm -rf "$CLEANUP"' EXIT

if ! git -C "$TPL" rev-parse --git-dir >/dev/null 2>&1; then
  echo "[FAIL] template is not a git repo: $TPL"; exit 2
fi
TPL_HEAD=$(git -C "$TPL" rev-parse HEAD 2>/dev/null) || { echo "[FAIL] template has no commits"; exit 2; }

# -- never run against the template itself ------------------------------------
tpl_top=$(git -C "$TPL" rev-parse --show-toplevel 2>/dev/null || true)
proj_top=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$proj_top" ] && [ -n "$tpl_top" ] && [ "$tpl_top" = "$proj_top" ]; then
  echo "[FAIL] this IS the template repo -- run from a project copy, not the template."
  exit 2
fi

write_marker() {
  mkdir -p "$(dirname "$MARKER")"
  printf 'sha=%s\nsource=%s\n' "$TPL_HEAD" "$SRC" > "$MARKER"
}

if [ "$SETBASE" -eq 1 ]; then
  write_marker
  echo "[OK] baseline set: ${TPL_HEAD:0:12} (source=$SRC)"
  exit 0
fi

# -- clean-tree guard (apply only) ---------------------------------------------
if [ "$APPLY" -eq 1 ] && [ "$FORCE_DIRTY" -ne 1 ] && [ -n "$proj_top" ]; then
  # workflows-coSherpa/.cosherpa/workflow-version is this tool's own bookkeeping file -- an uncommitted
  # marker (e.g. right after --set-baseline) must not trip the guard.
  if [ -n "$(git -C "$ROOT" status --porcelain 2>/dev/null | grep -vE '^.. workflows-coSherpa/\.cosherpa/workflow-version$')" ]; then
    echo "[FAIL] project working tree is dirty -- commit/stash first, or --force-dirty."
    exit 2
  fi
fi
if [ -z "$proj_top" ]; then
  echo "[WARN] project is not a git repo -- no dirty-guard and no easy undo. Consider git init first."
fi

# -- manifest (authoritative copy = template HEAD) -----------------------------
manifest_raw=$(git -C "$TPL" show "$TPL_HEAD:workflows-coSherpa/workflow-manifest.txt" 2>/dev/null) || {
  echo "[FAIL] template HEAD carries no workflows-coSherpa/workflow-manifest.txt -- commit it in the template first."
  exit 2
}

FILES=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="${line%"${line##*[![:space:]]}"}"   # rtrim
  [ -n "$line" ] || continue
  case "$line" in
    */)
      while IFS= read -r -d '' f; do
        FILES+=("$f")
      done < <(git -C "$TPL" ls-tree -r --name-only -z "$TPL_HEAD" -- "$line" 2>/dev/null)
      ;;
    *) FILES+=("$line") ;;
  esac
done <<< "$manifest_raw"

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "[FAIL] manifest expanded to zero files -- template state looks wrong."
  exit 2
fi

# -- base availability ----------------------------------------------------------
HAVE_BASE=0
if [ -n "$BASE_SHA" ]; then
  if git -C "$TPL" cat-file -e "$BASE_SHA^{commit}" 2>/dev/null; then
    HAVE_BASE=1
  else
    echo "[WARN] marker sha ${BASE_SHA:0:12} not found in template history -- treating as first run (REVIEW mode)."
  fi
fi

in_tree() { git -C "$TPL" cat-file -e "$1:$2" 2>/dev/null; }   # <sha> <path>
show_at() { git -C "$TPL" show "$1:$2" 2>/dev/null; }          # <sha> <path>

# -- classify -------------------------------------------------------------------
OKS=() NEWS=() UPDATES=() LOCALMODS=() CONFLICTS=() LOCALDELS=() REVIEWS=() UNCOMMITTED=()

for f in "${FILES[@]}"; do
  if ! in_tree "$TPL_HEAD" "$f"; then
    UNCOMMITTED+=("$f"); continue
  fi
  t=$(show_at "$TPL_HEAD" "$f" | tr -d '\r')
  if [ ! -f "$ROOT/$f" ]; then
    if [ "$HAVE_BASE" -eq 1 ] && in_tree "$BASE_SHA" "$f"; then
      LOCALDELS+=("$f")
    else
      NEWS+=("$f")
    fi
    continue
  fi
  l=$(tr -d '\r' < "$ROOT/$f")
  if [ "$l" = "$t" ]; then
    OKS+=("$f"); continue
  fi
  if [ "$HAVE_BASE" -eq 1 ]; then
    if in_tree "$BASE_SHA" "$f"; then
      b=$(show_at "$BASE_SHA" "$f" | tr -d '\r')
      if   [ "$l" = "$b" ]; then UPDATES+=("$f")
      elif [ "$t" = "$b" ]; then LOCALMODS+=("$f")
      else CONFLICTS+=("$f")
      fi
    else
      CONFLICTS+=("$f")   # added on both sides with different content
    fi
  else
    REVIEWS+=("$f")
  fi
done

# -- apply ------------------------------------------------------------------------
apply_file() {
  local f="$1" dest tmp mode
  dest="$ROOT/$f"
  mkdir -p "$(dirname "$dest")"
  tmp=$(mktemp "$ROOT/.wf-update.XXXXXX" 2>/dev/null || mktemp "${TMPDIR:-/tmp}/cosherpa.XXXXXX") || return 1
  if ! git -C "$TPL" show "$TPL_HEAD:$f" > "$tmp"; then
    rm -f "$tmp"; return 1
  fi
  mv -f "$tmp" "$dest" || return 1      # rename: safe even for this running script
  mode=$(git -C "$TPL" ls-tree "$TPL_HEAD" -- "$f" 2>/dev/null | awk '{print $1; exit}')
  [ "$mode" = "100755" ] && chmod +x "$dest"
  return 0
}

applied=0 apply_failed=0
if [ "$APPLY" -eq 1 ]; then
  for f in ${NEWS[@]+"${NEWS[@]}"} ${UPDATES[@]+"${UPDATES[@]}"}; do
    if apply_file "$f"; then
      applied=$((applied + 1))
    else
      echo "[FAIL] could not write: $f"
      apply_failed=$((apply_failed + 1))
    fi
  done
fi

# -- report ------------------------------------------------------------------------
mode_label="dry-run (report only; use --apply)"
[ "$APPLY" -eq 1 ] && mode_label="apply"
echo "=== update-workflow: $mode_label ==="
echo "  template: $SRC @ ${TPL_HEAD:0:12}"
if [ "$HAVE_BASE" -eq 1 ]; then
  echo "  baseline: ${BASE_SHA:0:12} (workflows-coSherpa/.cosherpa/workflow-version)"
else
  echo "  baseline: (none -- first run)"
fi
echo "  in sync: ${#OKS[@]}  new: ${#NEWS[@]}  update: ${#UPDATES[@]}  local-mod: ${#LOCALMODS[@]}  conflict: ${#CONFLICTS[@]}  local-del: ${#LOCALDELS[@]}  review: ${#REVIEWS[@]}  template-uncommitted: ${#UNCOMMITTED[@]}"

group() { # <label> <entries...>
  local label="$1"; shift
  [ "$#" -gt 0 ] || return 0
  echo "$label"
  printf '    %s\n' "$@"
}
group "  [NEW] missing here, will be/was created:"            ${NEWS[@]+"${NEWS[@]}"}
group "  [UPDATE] clean local copy, template advanced:"       ${UPDATES[@]+"${UPDATES[@]}"}
group "  [LOCAL-MOD] project customization kept (no action):" ${LOCALMODS[@]+"${LOCALMODS[@]}"}
group "  [LOCAL-DEL] deleted by the project, respected:"      ${LOCALDELS[@]+"${LOCALDELS[@]}"}
group "  [CONFLICT] BOTH sides changed -- reconcile by hand:" ${CONFLICTS[@]+"${CONFLICTS[@]}"}
group "  [REVIEW] differs from template (no baseline yet):"   ${REVIEWS[@]+"${REVIEWS[@]}"}
group "  [WARN] in manifest but not committed in template:"   ${UNCOMMITTED[@]+"${UNCOMMITTED[@]}"}

pending=$(( ${#CONFLICTS[@]} + ${#REVIEWS[@]} ))
if [ "$pending" -gt 0 ]; then
  echo
  echo "  For each [CONFLICT]/[REVIEW] file: inspect, then either keep yours or adopt the template:"
  echo "    diff -u <file> <(git -C \"$TPL\" show $TPL_HEAD:<file>)     # inspect"
  echo "    git -C \"$TPL\" show $TPL_HEAD:<file> > <file>              # adopt template version"
  echo "  When everything is reconciled:  bash workflows-coSherpa/scripts/update-workflow.sh --set-baseline"
fi

if [ "$APPLY" -eq 1 ]; then
  echo
  echo "  applied: $applied file(s)"
  if [ "$apply_failed" -gt 0 ]; then
    echo "[FAIL] $apply_failed file(s) failed to write"
    exit 2
  fi
  if [ "$pending" -eq 0 ]; then
    write_marker
    echo "[OK] baseline updated -> ${TPL_HEAD:0:12}"
  else
    if [ ! -f "$MARKER" ]; then
      # remember the source now so later runs need no --from;
      # the sha line is written only once everything is reconciled.
      mkdir -p "$(dirname "$MARKER")"
      printf 'source=%s\n' "$SRC" > "$MARKER"
      echo "[..] template source remembered in workflows-coSherpa/.cosherpa/workflow-version (sha pending reconcile)"
    fi
    echo "[..] baseline NOT updated ($pending pending) -- resolve, then run --set-baseline."
  fi
fi

[ "$pending" -eq 0 ] || exit 1
exit 0
