#!/usr/bin/env bash
# red-first-check.sh -- conversion-time gate-validity hygiene.
#
# Run RIGHT AFTER `/build` mode B converts issues/PRD into goals/<n>-*.
# At that moment nothing is implemented yet, so EVERY new goal's gate must
# FAIL (red). This catches two opposite ways a gate can be worthless:
#
#   * GREEN pre-implementation  -> the gate checks nothing (`exit 0` /
#     tautology / bare `test -f`). Hard FAIL.
#   * RED from a WIRING error   -> the gate fails to *run* (bad runner
#     invocation, missing command/module, syntax error), so it can never go
#     green no matter how correct the code is. WARNING (could be a false
#     positive; RED->GREEN would also surface it) -- but flagged here early,
#     because red-first alone would wave it through as "red = has teeth".
#
# Complements check-gate-rigor.sh (which catches faked universality). See
# AGENTS.md "Gate validity (Phase 1->2)".
#
# NOT for steady state: once goals are partially built, a green goal is
# legitimate. This is a one-shot, conversion-time check.
#
# Usage:
#   red-first-check.sh              # check $GOALS_DIR (default goals/)
#   GOALS_DIR=path red-first-check.sh
#   red-first-check.sh --self-test
#
# Exit 0 = every checked gate is red for a real (assertion) reason. Exit 1 =
# a gate was green pre-implementation, or no convertible goals were found.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/_portable.sh"
export GATES_SKIP_DEEP="${GATES_SKIP_DEEP:-1}"

# Stack-agnostic signatures of a gate that FAILS TO RUN (vs. fails an
# assertion). These mean the harness/command is mis-wired, not that the code
# is missing -- such a gate can never turn green.
WIRING_RE='command not found|not recognized as|no such file or directory|cannot find module|module_not_found|modulenotfounderror|no module named|cannot find package|syntaxerror|syntax error near|permission denied'

check_dir() {
  local gdir="$1" n=0 green="" broken="" md name gate out rc
  if [ ! -d "$gdir" ]; then
    echo "red-first-check: no goals dir: $gdir"
    return 1
  fi

  # Bootstrap leftover: the 0-example placeholder beside real numbered goals
  # means build mode B did not delete it -- it would linger as a permanently
  # green live goal. The conversion-time check is the natural place to catch this.
  if [ -f "$gdir/0-example.gates.sh" ] || [ -f "$gdir/0-example.md" ]; then
    local realcount
    realcount=$(find "$gdir" -maxdepth 1 -type f -name '[1-9]*.md' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$realcount" -gt 0 ]; then
      echo "red-first-check: WARNING -- goals/0-example.* still present beside real goals;"
      echo "  build mode B must delete the placeholder triplet (else it lingers as a green goal)."
    fi
  fi

  while IFS= read -r md; do
    [ -z "$md" ] && continue
    name="$(basename "$md" .md)"
    case "$name" in 0-example|_meta) continue ;; esac   # placeholder / cross-cutting
    gate="$gdir/${name}.gates.sh"
    [ -f "$gate" ] || { echo "  ? $name (no gate script)"; continue; }
    n=$((n + 1))
    out="$(bash "$gate" 2>&1)"; rc=$?
    if [ "$rc" -eq 0 ]; then
      green="${green}  GREEN before implementation: ${name} (gate checks nothing -- tautology suspect)"$'\n'
    elif printf '%s' "$out" | grep -qiE "$WIRING_RE"; then
      broken="${broken}  BROKEN WIRING: ${name} (red from a run error, not an assertion -- may never go green)"$'\n'
    fi
  done < <(find "$gdir" -maxdepth 1 -type f -name '[0-9]*.md' 2>/dev/null | portable_version_sort)

  if [ "$n" -eq 0 ]; then
    echo "red-first-check: no convertible goals in $gdir (run after /build mode B)"
    return 1
  fi

  # Broken-wiring is a warning, not a failure on its own (possible false
  # positive; RED->GREEN will also surface it). It is printed before the verdict.
  if [ -n "$broken" ]; then
    echo "red-first-check: WARNING -- a gate is red from a wiring error, not a real assertion:"
    printf '%s' "$broken"
    echo "  Confirm the gate actually exercises the code (a test runner pointed at real files,"
    echo "  not a bare directory or a missing command/module)."
  fi

  if [ -n "$green" ]; then
    echo "red-first-check: FAIL -- a gate passed on pre-implementation code:"
    printf '%s' "$green"
    echo "  Fix the .gates.sh so it genuinely fails until the work is done."
    return 1
  fi
  echo "red-first-check: OK -- all $n goal gates are red for an assertion reason (they have teeth)"
  return 0
}

self_test() {
  local tmp fails=0 out rc
  tmp="$(portable_mktemp_dir)"
  trap 'rm -rf "$tmp"' RETURN

  mkdir -p "$tmp/red"
  printf '# g1\n' > "$tmp/red/1-a.md"; printf '#!/usr/bin/env bash\nexit 1\n' > "$tmp/red/1-a.gates.sh"
  printf '# g2\n' > "$tmp/red/2-b.md"; printf '#!/usr/bin/env bash\nexit 1\n' > "$tmp/red/2-b.gates.sh"
  if check_dir "$tmp/red" >/dev/null; then echo "  [PASS] all-red -> exit 0"; else echo "  [FAIL] all-red expected 0"; fails=1; fi

  mkdir -p "$tmp/taut"
  printf '# g1\n' > "$tmp/taut/1-a.md"; printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/taut/1-a.gates.sh"
  printf '# g2\n' > "$tmp/taut/2-b.md"; printf '#!/usr/bin/env bash\nexit 1\n' > "$tmp/taut/2-b.gates.sh"
  if check_dir "$tmp/taut" >/dev/null; then echo "  [FAIL] tautology expected 1"; fails=1; else echo "  [PASS] tautology(green) -> exit 1"; fi

  mkdir -p "$tmp/empty"
  if check_dir "$tmp/empty" >/dev/null; then echo "  [FAIL] empty expected 1"; fails=1; else echo "  [PASS] empty -> exit 1"; fi

  # broken wiring: red, but from a missing command -> warn, still exit 0
  mkdir -p "$tmp/broken"
  printf '# g1\n' > "$tmp/broken/1-a.md"; printf '#!/usr/bin/env bash\nthis_cmd_does_not_exist_xyz_123\n' > "$tmp/broken/1-a.gates.sh"
  out="$(check_dir "$tmp/broken")"; rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'BROKEN WIRING'; then echo "  [PASS] broken-wiring -> warned, exit 0"; else echo "  [FAIL] broken-wiring not warned/exit"; fails=1; fi

  # bootstrap leftover: 0-example beside a real goal -> warn
  mkdir -p "$tmp/left"
  printf '# ex\n' > "$tmp/left/0-example.md"; printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/left/0-example.gates.sh"
  printf '# g1\n' > "$tmp/left/1-a.md"; printf '#!/usr/bin/env bash\nexit 1\n' > "$tmp/left/1-a.gates.sh"
  out="$(check_dir "$tmp/left")"
  if printf '%s' "$out" | grep -q '0-example'; then echo "  [PASS] 0-example leftover -> warned"; else echo "  [FAIL] leftover not warned"; fails=1; fi

  [ "$fails" = 0 ] && echo "red-first-check self-test: ALL PASS" || echo "red-first-check self-test: FAILURES"
  return $fails
}

case "${1:-}" in
  --self-test) echo "red-first-check self-test:"; self_test ;;
  *)           check_dir "${GOALS_DIR:-$ROOT/goals}" ;;
esac
