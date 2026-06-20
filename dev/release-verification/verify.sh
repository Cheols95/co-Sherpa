#!/usr/bin/env bash
# verify.sh -- deterministic developer verification entrypoint for co-Sherpa.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERIFY_REL="dev/release-verification/verify.sh"
RELEASE_REPORT_REL="dev/release-verification/release-report.md"
EXPECTED_PLUGIN_ID="cosherpa"
EXPECTED_DISPLAY_NAME="co-Sherpa"
HARNESS_ROOT="workflows-coSherpa"
LEGACY_HARNESS_DIR="workflows"

FAILURES=0

usage() {
  cat <<'EOF'
Usage:
  bash dev/release-verification/verify.sh quick
  bash dev/release-verification/verify.sh static
  bash dev/release-verification/verify.sh unit
  bash dev/release-verification/verify.sh verifier
  bash dev/release-verification/verify.sh plugin
  bash dev/release-verification/verify.sh release
  bash dev/release-verification/verify.sh e2e-preflight
EOF
}

shell_quote() {
  local out="" part
  for part in "$@"; do
    printf -v part '%q' "$part"
    out="${out}${out:+ }${part}"
  done
  printf '%s\n' "$out"
}

pass() {
  echo "[PASS] $*"
}

fail() {
  echo "[FAIL] $*"
  FAILURES=$((FAILURES + 1))
}

skip() {
  echo "[SKIP] $*"
}

run_check() {
  local label="$1"
  shift
  echo
  echo "==> $label"
  echo "cmd: $(shell_quote "$@")"
  (
    cd "$REPO_ROOT" || exit 1
    "$@"
  )
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    pass "$label"
  else
    fail "$label (exit $rc)"
  fi
}

run_func() {
  local label="$1"
  local command_text="$2"
  local func="$3"
  shift 3
  echo
  echo "==> $label"
  echo "cmd: $command_text"
  "$func" "$@"
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    pass "$label"
  elif [ "$rc" -eq 3 ]; then
    skip "$label"
  else
    fail "$label (exit $rc)"
  fi
}

finish() {
  if [ "$FAILURES" -eq 0 ]; then
    echo
    pass "$1 profile passed"
    exit 0
  fi
  echo
  fail "$1 profile failed with $FAILURES failing check(s)"
  exit 1
}

require_file() {
  local path="$1"
  if [ ! -f "$REPO_ROOT/$path" ]; then
    echo "missing file: $path"
    return 1
  fi
}

require_dir() {
  local path="$1"
  if [ ! -d "$REPO_ROOT/$path" ]; then
    echo "missing directory: $path"
    return 1
  fi
}

check_manifest_identity() {
  local init_version
  init_version="$(sed -n 's/.*echo "version=\([^"]*\)".*/\1/p' \
    "$REPO_ROOT/workflows-coSherpa/plugin/src/bin/cosherpa-init" | head -1)"
  python3 - "$REPO_ROOT/workflows-coSherpa/plugin/platform/claude/plugin.json" \
    "$REPO_ROOT/workflows-coSherpa/plugin/platform/codex/plugin.json" \
    "$EXPECTED_PLUGIN_ID" "$EXPECTED_DISPLAY_NAME" "$init_version" <<'PY'
import json
import sys
from pathlib import Path

claude_path, codex_path, expected_id, expected_display, init_version = sys.argv[1:6]
errors = []

try:
    claude = json.loads(Path(claude_path).read_text(encoding="utf-8"))
    codex = json.loads(Path(codex_path).read_text(encoding="utf-8"))
except Exception as exc:
    print(f"manifest JSON parse failed: {exc}")
    sys.exit(1)

claude_id = claude.get("name")
codex_id = codex.get("name")
claude_version = claude.get("version")
codex_version = codex.get("version")
display = codex.get("interface", {}).get("displayName")

if claude_id != expected_id:
    errors.append(f"Claude plugin id mismatch: {claude_id!r} != {expected_id!r}")
if codex_id != expected_id:
    errors.append(f"Codex plugin id mismatch: {codex_id!r} != {expected_id!r}")
if claude_id != codex_id:
    errors.append(f"manifest name mismatch: claude={claude_id!r} codex={codex_id!r}")
if not claude_version or not codex_version:
    errors.append("missing manifest version")
elif claude_version != codex_version:
    errors.append(f"version mismatch: claude={claude_version!r} codex={codex_version!r}")
if not init_version:
    errors.append("missing cosherpa-init version")
elif claude_version and init_version != claude_version:
    errors.append(f"cosherpa-init version mismatch: init={init_version!r} != manifest={claude_version!r}")
if display != expected_display:
    errors.append(f"Codex displayName mismatch: {display!r} != {expected_display!r}")

print(f"identity: id={codex_id} version={codex_version} init={init_version} displayName={display}")
if errors:
    for error in errors:
        print(error)
    sys.exit(1)
PY
}

check_lifecycle_sources() {
  local name rc=0
  for name in init help migration; do
    require_file "workflows-coSherpa/plugin/src/skills/$name/SKILL.md" || rc=1
    require_file "workflows-coSherpa/plugin/platform/codex/skills/$name/agents/openai.yaml" || rc=1
  done
  return "$rc"
}

check_migration_v2_contract() {
  local skill="$REPO_ROOT/workflows-coSherpa/plugin/src/skills/migration/SKILL.md"
  local rc=0 required forbidden
  require_file "workflows-coSherpa/plugin/src/skills/migration/SKILL.md" || return 1

  for required in \
    "brownfield onboarding v2" \
    "workflows-coSherpa/docs/concept/migration-report.md" \
    "Candidate Ledger" \
    "Recommended Concept Queue" \
    "context-term" \
    "architecture-context" \
    "prd-candidate" \
    "spec-candidate" \
    "adr-candidate" \
    "finding-candidate" \
    "stale-or-superseded" \
    "question-required" \
    "Do not create or edit \`workflows-coSherpa/docs/adr/*\`" \
    "Do not modify application source" \
    "/concept workflows-coSherpa/docs/concept/migration-report.md"; do
    if ! grep -F -- "$required" "$skill" >/dev/null; then
      echo "migration v2 contract missing required text: $required"
      rc=1
    fi
  done

  for forbidden in \
    "seed accepted tradeoff ADRs" \
    "ADR seed" \
    "adr seed"; do
    if grep -F -- "$forbidden" "$skill" >/dev/null; then
      echo "migration v2 contract contains forbidden ADR-seed language: $forbidden"
      rc=1
    fi
  done

  return "$rc"
}

check_cosherpa_init_entrypoint() {
  local rc=0
  require_file "workflows-coSherpa/plugin/src/bin/cosherpa-init" || rc=1
  if [ -f "$REPO_ROOT/workflows-coSherpa/plugin/src/bin/cosherpa-init" ] &&
    [ ! -x "$REPO_ROOT/workflows-coSherpa/plugin/src/bin/cosherpa-init" ]; then
    echo "not executable: workflows-coSherpa/plugin/src/bin/cosherpa-init"
    rc=1
  fi
  return "$rc"
}

check_build_asset_roots() {
  local rc=0
  require_file "workflows-coSherpa/workflow-manifest.txt" || rc=1
  require_dir "workflows-coSherpa/skills" || rc=1
  require_dir "workflows-coSherpa/plugin/src/skills" || rc=1
  require_dir "workflows-coSherpa/plugin/src/bin" || rc=1
  return "$rc"
}

check_workflow_manifest_paths() {
  local manifest="$REPO_ROOT/workflows-coSherpa/workflow-manifest.txt"
  local line trimmed rc=0
  [ -f "$manifest" ] || { echo "missing manifest: workflows-coSherpa/workflow-manifest.txt"; return 1; }

  while IFS= read -r line || [ -n "$line" ]; do
    trimmed="${line%%#*}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    trimmed="${trimmed#"${trimmed%%[![:space:]]*}"}"
    [ -n "$trimmed" ] || continue
    if [[ "$trimmed" == */ ]]; then
      if [ ! -d "$REPO_ROOT/${trimmed%/}" ]; then
        echo "manifest directory missing: $trimmed"
        rc=1
      fi
    elif [ ! -f "$REPO_ROOT/$trimmed" ]; then
      echo "manifest file missing: $trimmed"
      rc=1
    fi
  done < "$manifest"

  return "$rc"
}

check_package_harness_root() {
  local package_lib="$REPO_ROOT/workflows-coSherpa/plugin/build/package-lib.sh"
  local source_root install_root
  source_root="$(sed -n 's/^PACKAGE_SOURCE_WORKFLOW_DIR="\([^"]*\)".*/\1/p' "$package_lib" | head -1)"
  install_root="$(sed -n 's/^PACKAGE_INSTALL_WORKFLOW_DIR="\([^"]*\)".*/\1/p' "$package_lib" | head -1)"

  if [ "$source_root" != "$HARNESS_ROOT" ] || [ "$install_root" != "$HARNESS_ROOT" ]; then
    echo "package harness root mismatch: source=$source_root install=$install_root expected=$HARNESS_ROOT"
    return 1
  fi
}

snapshot_dist_tree() {
  local dist="$REPO_ROOT/workflows-coSherpa/plugin/dist"
  local file rel sum mode
  [ -d "$dist" ] || return 1

  while IFS= read -r -d '' file; do
    rel="${file#"$REPO_ROOT/"}"
    mode="$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null || echo unknown)"
    sum="$(cksum < "$file")"
    printf 'file %s %s %s\n' "$mode" "$sum" "$rel"
  done < <(find "$dist" -type f -print0 | sort -z)

  while IFS= read -r -d '' file; do
    rel="${file#"$REPO_ROOT/"}"
    mode="$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null || echo unknown)"
    printf 'dir %s %s\n' "$mode" "$rel"
  done < <(find "$dist" -type d -print0 | sort -z)
}

check_dist_build_idempotent() {
  local before after
  before="$(mktemp "${TMPDIR:-/tmp}/cosherpa-dist-before.XXXXXX")" || return 1
  after="$(mktemp "${TMPDIR:-/tmp}/cosherpa-dist-after.XXXXXX")" || {
    rm -f "$before"
    return 1
  }

  snapshot_dist_tree > "$before" || {
    echo "could not snapshot dist before build"
    rm -f "$before" "$after"
    return 1
  }
  if ! (cd "$REPO_ROOT" && bash workflows-coSherpa/plugin/build/build.sh >/dev/null); then
    echo "build failed during dist idempotence check"
    rm -f "$before" "$after"
    return 1
  fi
  snapshot_dist_tree > "$after" || {
    echo "could not snapshot dist after build"
    rm -f "$before" "$after"
    return 1
  }

  if diff -u "$before" "$after"; then
    echo "dist build is idempotent"
    rm -f "$before" "$after"
    return 0
  fi

  echo "dist changed when build.sh was rerun"
  rm -f "$before" "$after"
  return 1
}

# Fail if the committed dist tree does not match a fresh build: build.sh has
# already regenerated dist in the working tree, so any porcelain entry means the
# tracked package output is stale (or carries uncommitted/untracked files).
# Returns 3 (SKIP) when not inside a git work tree.
check_dist_tracked_clean() {
  local dist_rel="workflows-coSherpa/plugin/dist" dirty
  if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "not a git work tree; cannot compare committed dist against build output"
    return 3
  fi
  dirty="$(git -C "$REPO_ROOT" status --porcelain -- "$dist_rel" 2>/dev/null)"
  if [ -n "$dirty" ]; then
    echo "committed dist differs from fresh build (regenerate and commit $dist_rel):"
    printf '%s\n' "$dirty" | sed 's/^/  /'
    return 1
  fi
  echo "committed dist matches fresh build: $dist_rel"
  return 0
}

run_init_in_fixture() {
  local fixture="$1"
  local temp_home="$2"
  (
    cd "$fixture" || exit 1
    CLAUDE_SKILLS_DIR="$temp_home/claude-skills" \
      CODEX_SKILLS_DIR="$temp_home/codex-skills" \
      CODEX_PROMPTS_DIR="$temp_home/codex-prompts" \
      COSHERPA_SKILL_BACKUP_DIR="$temp_home/skill-backups" \
      "$REPO_ROOT/workflows-coSherpa/plugin/dist/codex/bin/cosherpa-init" >/dev/null
  )
}

check_init_no_legacy_dir() {
  local tmp scratch migration rc=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/cosherpa-verify.XXXXXX")" || return 1

  scratch="$tmp/scratch"
  mkdir -p "$scratch"
  if ! run_init_in_fixture "$scratch" "$tmp/home-scratch"; then
    echo "scratch init failed"
    rc=1
  fi
  [ -d "$scratch/$HARNESS_ROOT" ] || { echo "scratch init did not create $HARNESS_ROOT"; rc=1; }
  [ ! -d "$scratch/$LEGACY_HARNESS_DIR" ] || { echo "scratch init created legacy harness directory"; rc=1; }

  migration="$tmp/migration-fixture"
  mkdir -p "$migration/src" "$migration/docs"
  printf '# Existing app\n' > "$migration/README.md"
  printf '{"name":"migration-fixture"}\n' > "$migration/package.json"
  printf 'console.log("fixture");\n' > "$migration/src/app.js"
  printf 'notes\n' > "$migration/docs/notes.md"
  if ! run_init_in_fixture "$migration" "$tmp/home-migration"; then
    echo "migration fixture init failed"
    rc=1
  fi
  [ -f "$migration/README.md" ] || { echo "migration fixture README was not preserved"; rc=1; }
  [ -f "$migration/src/app.js" ] || { echo "migration fixture source was not preserved"; rc=1; }
  [ -d "$migration/$HARNESS_ROOT" ] || { echo "migration fixture did not create $HARNESS_ROOT"; rc=1; }
  [ ! -d "$migration/$LEGACY_HARNESS_DIR" ] || { echo "migration fixture created legacy harness directory"; rc=1; }

  rm -rf "$tmp"
  return "$rc"
}

canary_check_gate_rigor() {
  local tmp rc=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/cosherpa-rigor.XXXXXX")" || return 1
  mkdir -p "$tmp/scripts" "$tmp/goals"
  cp "$REPO_ROOT/workflows-coSherpa/scripts/check-gate-rigor.sh" "$tmp/scripts/"
  cp "$REPO_ROOT/workflows-coSherpa/scripts/_goals-lib.sh" "$tmp/scripts/"
  cp "$REPO_ROOT/workflows-coSherpa/scripts/_portable.sh" "$tmp/scripts/"

  cat > "$tmp/goals/1-universal.md" <<'EOF'
# Universal

Every file must be verified.
EOF
  cat > "$tmp/goals/1-universal.gates.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$tmp/goals/1-universal.gates.sh"
  if bash "$tmp/scripts/check-gate-rigor.sh" --all >/dev/null 2>&1; then
    echo "narrow gate unexpectedly passed universal-claim fixture"
    rc=1
  else
    echo "negative control: universal claim without iteration failed as expected"
  fi

  cat > "$tmp/goals/1-universal.gates.sh" <<'EOF'
#!/usr/bin/env bash
for file in goals/*.md; do
  [ -f "$file" ] || exit 1
done
exit 0
EOF
  chmod +x "$tmp/goals/1-universal.gates.sh"
  if bash "$tmp/scripts/check-gate-rigor.sh" --all >/dev/null 2>&1; then
    echo "positive control: universal claim with iteration passed"
  else
    echo "iterating gate unexpectedly failed"
    rc=1
  fi

  rm -rf "$tmp"
  return "$rc"
}

canary_red_first() {
  local tmp rc=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/cosherpa-red-first.XXXXXX")" || return 1

  mkdir -p "$tmp/taut"
  printf '# Tautology\n' > "$tmp/taut/1-taut.md"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/taut/1-taut.gates.sh"
  chmod +x "$tmp/taut/1-taut.gates.sh"
  if GOALS_DIR="$tmp/taut" RED_FIRST_RECORD_DIR="$tmp/records-taut" \
    bash "$REPO_ROOT/workflows-coSherpa/scripts/red-first-check.sh" >/dev/null 2>&1; then
    echo "tautology gate unexpectedly passed red-first"
    rc=1
  else
    echo "negative control: tautology gate failed as expected"
  fi

  mkdir -p "$tmp/red"
  printf '# Red\n' > "$tmp/red/1-red.md"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$tmp/red/1-red.gates.sh"
  chmod +x "$tmp/red/1-red.gates.sh"
  if GOALS_DIR="$tmp/red" RED_FIRST_RECORD_DIR="$tmp/records-red" \
    bash "$REPO_ROOT/workflows-coSherpa/scripts/red-first-check.sh" >/dev/null; then
    echo "positive control: assertion-red gate passed red-first"
  else
    echo "assertion-red gate unexpectedly failed red-first"
    rc=1
  fi

  rm -rf "$tmp"
  return "$rc"
}

canary_template_clean() {
  local tmp project workflow rc=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/cosherpa-template-clean.XXXXXX")" || return 1
  project="$tmp/project"
  workflow="$project/$HARNESS_ROOT"

  mkdir -p "$workflow/scripts" "$workflow/dashboard/engines" \
    "$workflow/docs/prd" "$workflow/docs/issues" "$workflow/docs/concept" \
    "$workflow/docs/spec" "$workflow/docs/adr" "$workflow/docs/findings" \
    "$workflow/goals" "$workflow/cycles" \
    "$project/.claude/skills/roadmap" "$project/.agents/skills/roadmap"
  cp "$REPO_ROOT/workflows-coSherpa/scripts/template-clean-check.sh" "$workflow/scripts/"
  cp "$REPO_ROOT/workflows-coSherpa/scripts/_portable.sh" "$workflow/scripts/"
  cp "$REPO_ROOT/workflows-coSherpa/scripts/_deps-lib.sh" "$workflow/scripts/"
  cp "$REPO_ROOT/workflows-coSherpa/dashboard/engines/roadmap.sh" "$workflow/dashboard/engines/"
  cp "$REPO_ROOT/workflows-coSherpa/dashboard/engines/roadmap-selftest.sh" "$workflow/dashboard/engines/"
  printf '# Roadmap\n' > "$workflow/dashboard/README.md"
  printf '# Roadmap skill\n' > "$project/.claude/skills/roadmap/SKILL.md"
  printf '# Roadmap skill\n' > "$project/.agents/skills/roadmap/SKILL.md"
  printf '# Dirty PRD\n' > "$workflow/docs/prd/PRD.md"
  printf '# Dirty Issue\nStatus: ready-for-agent\n' > "$workflow/docs/issues/001-dirty.md"
  printf '# Dirty Spec\n' > "$workflow/docs/spec/data-schema.md"
  printf '# Dirty ADR\n' > "$workflow/docs/adr/0001-decision.md"
  printf '# Dirty Finding\n' > "$workflow/docs/findings/2026-01-01T0000-dirty.md"
  printf '# Dirty Cycle\n' > "$workflow/cycles/250101-01-dirty.md"

  if bash "$workflow/scripts/template-clean-check.sh" >/dev/null 2>&1; then
    echo "dirty template fixture unexpectedly passed"
    rc=1
  else
    echo "negative control: dirty template fixture failed as expected"
  fi

  rm -rf "$tmp"
  return "$rc"
}

write_release_report_header() {
  local report="$REPO_ROOT/$RELEASE_REPORT_REL"
  local generated_at branch commit status
  generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  branch="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  commit="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  status="$(git -C "$REPO_ROOT" status --short 2>/dev/null || true)"

  mkdir -p "$(dirname "$report")"
  cat > "$report" <<EOF
# co-Sherpa Release Verification Report

- generated_at: $generated_at
- branch: $branch
- commit: $commit
- plugin_id: $EXPECTED_PLUGIN_ID
- display_name: $EXPECTED_DISPLAY_NAME
- harness_root: $HARNESS_ROOT/
- verdict: PENDING

## Workspace Status Before Release

\`\`\`text
${status:-clean}
\`\`\`

## Command Results

EOF
}

append_release_report() {
  printf '%s\n' "$@" >> "$REPO_ROOT/$RELEASE_REPORT_REL"
}

record_release_step() {
  local label="$1"
  local command_text="$2"
  local rc="$3"
  local log_file="$4"
  local status="PASS"
  if [ "$rc" -eq 3 ]; then
    status="SKIP"
  elif [ "$rc" -ne 0 ]; then
    status="FAIL"
  fi

  append_release_report "### $label"
  append_release_report ""
  append_release_report "- command: \`$command_text\`"
  append_release_report "- exit_code: \`$rc\`"
  append_release_report "- status: \`$status\`"
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 3 ]; then
    append_release_report ""
    append_release_report "Last 80 log lines:"
    append_release_report ""
    append_release_report '```text'
    tail -80 "$log_file" >> "$REPO_ROOT/$RELEASE_REPORT_REL" 2>/dev/null || true
    append_release_report '```'
  fi
  append_release_report ""
}

run_release_step() {
  local label="$1"
  shift
  local tmp rc command_text
  tmp="$(mktemp "${TMPDIR:-/tmp}/cosherpa-release-step.XXXXXX")" || {
    fail "$label (could not create temp log)"
    return 1
  }
  command_text="$(shell_quote "$@")"

  echo
  echo "==> $label"
  echo "cmd: $command_text"
  (
    cd "$REPO_ROOT" || exit 1
    "$@"
  ) >"$tmp" 2>&1
  rc=$?
  cat "$tmp"
  record_release_step "$label" "$command_text" "$rc" "$tmp"
  rm -f "$tmp"

  if [ "$rc" -eq 0 ]; then
    pass "$label"
  else
    fail "$label (exit $rc)"
  fi
}

run_release_func() {
  local label="$1"
  local command_text="$2"
  local func="$3"
  shift 3
  local tmp rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/cosherpa-release-step.XXXXXX")" || {
    fail "$label (could not create temp log)"
    return 1
  }

  echo
  echo "==> $label"
  echo "cmd: $command_text"
  "$func" "$@" >"$tmp" 2>&1
  rc=$?
  cat "$tmp"
  record_release_step "$label" "$command_text" "$rc" "$tmp"
  rm -f "$tmp"

  if [ "$rc" -eq 0 ]; then
    pass "$label"
  elif [ "$rc" -eq 3 ]; then
    skip "$label"
  else
    fail "$label (exit $rc)"
  fi
}

check_release_dist_clean() {
  local dist="$REPO_ROOT/workflows-coSherpa/plugin/dist"
  local rc=0 bad root

  [ -d "$dist/claude" ] || { echo "missing dist root: workflows-coSherpa/plugin/dist/claude"; rc=1; }
  [ -d "$dist/codex" ] || { echo "missing dist root: workflows-coSherpa/plugin/dist/codex"; rc=1; }
  [ -f "$dist/claude/.claude-plugin/plugin.json" ] || { echo "missing Claude plugin manifest in dist"; rc=1; }
  [ -f "$dist/codex/.codex-plugin/plugin.json" ] || { echo "missing Codex plugin manifest in dist"; rc=1; }
  [ -x "$dist/claude/bin/cosherpa-init" ] || { echo "Claude dist cosherpa-init missing or not executable"; rc=1; }
  [ -x "$dist/codex/bin/cosherpa-init" ] || { echo "Codex dist cosherpa-init missing or not executable"; rc=1; }

  bad="$(find "$dist" -type d -name "$LEGACY_HARNESS_DIR" -print 2>/dev/null | sed "s#^$REPO_ROOT/##")"
  if [ -n "$bad" ]; then
    echo "legacy harness directories found in dist:"
    printf '%s\n' "$bad" | sed 's/^/  - /'
    rc=1
  fi

  bad="$(find "$dist" \( -type d \( -name .state -o -name .cosherpa \) -o \
    -type f \( -name audit_agent_report.html -o -name release-report.md \) \) \
    -print 2>/dev/null | sed "s#^$REPO_ROOT/##")"
  if [ -n "$bad" ]; then
    echo "runtime/report artifacts found in dist:"
    printf '%s\n' "$bad" | sed 's/^/  - /'
    rc=1
  fi

  bad="$(find "$dist" \( -path '*/dev/release-verification/*' -o -name e2e_shop_demo -o -name 'e2e_migration_fixture*' \) \
    -print 2>/dev/null | sed "s#^$REPO_ROOT/##")"
  if [ -n "$bad" ]; then
    echo "developer verification artifacts found in dist:"
    printf '%s\n' "$bad" | sed 's/^/  - /'
    rc=1
  fi

  while IFS= read -r root; do
    [ -n "$root" ] || continue
    bad="$(find "$root/docs/prd" -maxdepth 1 -type f ! -name README.md -print 2>/dev/null | sed "s#^$REPO_ROOT/##")"
    [ -z "$bad" ] || { echo "project PRD files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }

    bad="$(find "$root/docs/issues" -maxdepth 1 -type f ! -name README.md -print 2>/dev/null | sed "s#^$REPO_ROOT/##")"
    [ -z "$bad" ] || { echo "project issue files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }

    bad="$(find "$root/docs/concept" -maxdepth 1 -type f 2>/dev/null |
      sed "s#^$REPO_ROOT/##" |
      grep -Ev '/(AGENTS\.md|CLAUDE\.md|README\.md)$' || true)"
    [ -z "$bad" ] || { echo "project concept files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }

    bad="$(find "$root/goals" -maxdepth 1 -type f 2>/dev/null |
      sed "s#^$REPO_ROOT/##" |
      grep -Ev '/(AGENTS\.md|CLAUDE\.md|EXAMPLE\.md|0-example\.(md|gates\.sh|next-task\.sh)|_meta\.(md|gates\.sh|next-task\.sh))$' || true)"
    [ -z "$bad" ] || { echo "project goal files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }

    bad="$(find "$root/docs/spec" -maxdepth 1 -type f 2>/dev/null |
      sed "s#^$REPO_ROOT/##" |
      grep -Ev '/(AGENTS\.md|CLAUDE\.md|README\.md)$' || true)"
    [ -z "$bad" ] || { echo "project spec files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }

    bad="$(find "$root/docs/adr" -maxdepth 1 -type f 2>/dev/null |
      sed "s#^$REPO_ROOT/##" |
      grep -Ev '/(AGENTS\.md|CLAUDE\.md|README\.md)$' || true)"
    [ -z "$bad" ] || { echo "project ADR files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }

    bad="$(find "$root/docs/findings" -maxdepth 1 -type f 2>/dev/null |
      sed "s#^$REPO_ROOT/##" |
      grep -Ev '/(AGENTS\.md|CLAUDE\.md|EXAMPLE\.md|README\.md)$' || true)"
    [ -z "$bad" ] || { echo "project finding files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }

    bad="$(find "$root/cycles" -maxdepth 1 -type f 2>/dev/null |
      sed "s#^$REPO_ROOT/##" |
      grep -Ev '/(AGENTS\.md|CLAUDE\.md|EXAMPLE\.md|README\.md)$' || true)"
    [ -z "$bad" ] || { echo "project cycle files found in dist template:"; printf '%s\n' "$bad" | sed 's/^/  - /'; rc=1; }
  done < <(find "$dist" -type d -name "$HARNESS_ROOT" -print 2>/dev/null)

  if [ "$rc" -eq 0 ]; then
    echo "release dist is clean: no runtime, report, E2E, project PRD/issue/concept/goal/spec/ADR/finding/cycle artifacts found"
  fi
  return "$rc"
}

finalize_release_report() {
  local verdict="$1"
  local status
  status="$(git -C "$REPO_ROOT" status --short 2>/dev/null || true)"

  append_release_report "## Workspace Status After Release"
  append_release_report ""
  append_release_report '```text'
  printf '%s\n' "${status:-clean}" >> "$REPO_ROOT/$RELEASE_REPORT_REL"
  append_release_report '```'
  append_release_report ""
  append_release_report "## Final Verdict"
  append_release_report ""
  append_release_report "$verdict"
  append_release_report ""

  python3 - "$REPO_ROOT/$RELEASE_REPORT_REL" "$verdict" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
verdict = sys.argv[2]
text = path.read_text(encoding="utf-8")
text = text.replace("- verdict: PENDING", f"- verdict: {verdict}", 1)
path.write_text(text, encoding="utf-8")
PY
}

profile_static() {
  run_check "git diff whitespace check" git diff --check
  run_check "verify.sh shell syntax" bash -n "$VERIFY_REL"
  run_check "plugin build.sh shell syntax" bash -n workflows-coSherpa/plugin/build/build.sh
  run_check "plugin release-check.sh shell syntax" bash -n workflows-coSherpa/plugin/build/release-check.sh
  run_check "template-clean-check.sh shell syntax" bash -n workflows-coSherpa/scripts/template-clean-check.sh
  run_check "check-gate-rigor.sh shell syntax" bash -n workflows-coSherpa/scripts/check-gate-rigor.sh
  run_check "red-first-check.sh shell syntax" bash -n workflows-coSherpa/scripts/red-first-check.sh
  run_check "roadmap-selftest.sh shell syntax" bash -n workflows-coSherpa/dashboard/engines/roadmap-selftest.sh
  run_func "Claude/Codex manifest identity audit" "python3 parse plugin manifests" check_manifest_identity
  run_func "lifecycle skill source audit" "test init/help/migration skill sources and Codex overlays" check_lifecycle_sources
  run_func "migration v2 contract audit" "test migration skill candidate-ledger/report/no-ADR-seed contract" check_migration_v2_contract
  run_func "cosherpa-init entrypoint audit" "test source entrypoint exists and is executable" check_cosherpa_init_entrypoint
  run_func "build asset root audit" "test package asset roots exist" check_build_asset_roots
  run_func "workflow manifest path audit" "test workflow-manifest.txt paths exist" check_workflow_manifest_paths
  run_func "release harness root audit" "test package root is workflows-coSherpa" check_package_harness_root
  run_func "scratch and migration fixture root audit" "run cosherpa-init in temporary fixtures and reject legacy harness directory" check_init_no_legacy_dir
  finish static
}

profile_unit() {
  run_check "roadmap self-test" bash workflows-coSherpa/dashboard/engines/roadmap-selftest.sh
  run_check "check-gate-rigor self-test" bash workflows-coSherpa/scripts/check-gate-rigor.sh --self-test
  run_check "red-first-check self-test" bash workflows-coSherpa/scripts/red-first-check.sh --self-test
  finish unit
}

profile_verifier() {
  run_check "check-gate-rigor self-test" bash workflows-coSherpa/scripts/check-gate-rigor.sh --self-test
  run_check "red-first-check self-test" bash workflows-coSherpa/scripts/red-first-check.sh --self-test
  run_check "roadmap self-test" bash workflows-coSherpa/dashboard/engines/roadmap-selftest.sh
  run_func "template-clean-check canary" "temporary dirty template fixture should fail template-clean-check.sh" canary_template_clean
  run_func "check-gate-rigor canary" "temporary universal-claim fixture should fail, then pass with iteration" canary_check_gate_rigor
  run_func "red-first-check canary" "temporary tautology gate should fail and assertion-red gate should pass" canary_red_first
  finish verifier
}

profile_quick() {
  # Sub-profiles are run as independent processes so each stays runnable on its
  # own; the resulting git-diff-check and self-test overlap with static/unit is
  # intentional redundancy, not a bug.
  run_check "git diff whitespace check" git diff --check
  run_check "static profile" bash "$VERIFY_REL" static
  run_check "unit profile" bash "$VERIFY_REL" unit
  run_check "verifier profile" bash "$VERIFY_REL" verifier
  finish quick
}

profile_plugin() {
  run_check "plugin build" bash workflows-coSherpa/plugin/build/build.sh
  run_check "plugin release-check" bash workflows-coSherpa/plugin/build/release-check.sh
  run_func "plugin dist idempotence check" "re-run build.sh and compare dist snapshot" check_dist_build_idempotent
  run_func "plugin dist tracked-clean check" "git status --porcelain on workflows-coSherpa/plugin/dist after build" check_dist_tracked_clean
  if [ "$FAILURES" -ne 0 ]; then
    echo "dist sync note: if workflows-coSherpa/plugin/dist changed, regenerate and commit the tracked package output."
  fi
  finish plugin
}

profile_release() {
  write_release_report_header
  echo "release report: $RELEASE_REPORT_REL"
  run_release_step "quick regression profile" bash "$VERIFY_REL" quick
  run_release_step "rebuild release package dist" bash workflows-coSherpa/plugin/build/build.sh
  run_release_func "release package cleanliness audit" "verify dist has no runtime/report/E2E/project artifacts" check_release_dist_clean
  run_release_step "release-check" bash workflows-coSherpa/plugin/build/release-check.sh
  run_release_func "post-release package cleanliness audit" "verify dist remains clean after release-check" check_release_dist_clean
  run_release_func "plugin dist idempotence check" "re-run build.sh and compare dist snapshot" check_dist_build_idempotent
  run_release_func "plugin dist tracked-clean check" "git status --porcelain on workflows-coSherpa/plugin/dist after rebuilds" check_dist_tracked_clean
  if [ "$FAILURES" -eq 0 ]; then
    pass "release verification passed"
    finalize_release_report "PASS"
  else
    finalize_release_report "FAIL"
  fi
  echo "release report written: $RELEASE_REPORT_REL"
  finish release
}

profile_e2e_preflight() {
  run_func "E2E goal prompt exists" "test -f dev/release-verification/cosherpa-e2e-goal.md" require_file \
    dev/release-verification/cosherpa-e2e-goal.md
  run_func "Mini Commerce Ops scenario exists" "test -f dev/release-verification/mini-commerce-ops-scenario.md" require_file \
    dev/release-verification/mini-commerce-ops-scenario.md
  run_func "audit report template exists" "test -f dev/release-verification/audit_agent_report.template.html" require_file \
    dev/release-verification/audit_agent_report.template.html

  echo
  echo "==> scratch target status"
  echo "cmd: inspect e2e_shop_demo"
  if [ ! -e "$REPO_ROOT/e2e_shop_demo" ]; then
    pass "scratch target is free: e2e_shop_demo does not exist"
  elif [ -d "$REPO_ROOT/e2e_shop_demo" ] &&
    [ -z "$(find "$REPO_ROOT/e2e_shop_demo" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]; then
    pass "scratch target exists and is empty: e2e_shop_demo"
  else
    skip "e2e_shop_demo is non-empty; full E2E agent must choose preserve, overwrite, or timestamp suffix"
  fi

  echo
  echo "==> existing audit report status"
  echo "cmd: inspect audit_agent_report.html"
  if [ -f "$REPO_ROOT/audit_agent_report.html" ]; then
    skip "audit_agent_report.html already exists; full E2E agent must choose overwrite or preserve"
  else
    pass "audit_agent_report.html is not present"
  fi

  echo
  echo "migration fixture note: full E2E creates its migration fixture in a safe temporary or timestamped path."
  echo "To run full E2E, give dev/release-verification/cosherpa-e2e-goal.md to Codex goal."
  finish e2e-preflight
}

PROFILE="${1:-}"
case "$PROFILE" in
  quick) profile_quick ;;
  static) profile_static ;;
  unit) profile_unit ;;
  verifier) profile_verifier ;;
  plugin) profile_plugin ;;
  release) profile_release ;;
  e2e-preflight) profile_e2e_preflight ;;
  *)
    usage
    exit 2
    ;;
esac
