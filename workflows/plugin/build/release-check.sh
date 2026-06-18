#!/usr/bin/env bash
# release-check.sh -- one release interface for the cosherpa plugin package.
#
# Runs the checks that must be true before publishing the Claude/Codex plugin:
# package regeneration, artifact mode/LF audit, host validators, Codex install
# smoke, scratch project init, template-clean check, and release metadata audit.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$WORKFLOW_ROOT/.." && pwd)"

if [ -f "$WORKFLOW_ROOT/scripts/_portable.sh" ]; then
  . "$WORKFLOW_ROOT/scripts/_portable.sh"
else
  portable_mktemp_dir() { mktemp -d 2>/dev/null || mktemp -d "${TMPDIR:-/tmp}/cosherpa.XXXXXX"; }
fi

STAGE_DIR=$(portable_mktemp_dir) || exit 2
PASS=true
STEP=0

cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

section() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP] $1"
}

fail() {
  echo "  [FAIL] $*"
  PASS=false
}

pass() {
  echo "  [PASS] $*"
}

run_checked() {
  local label="$1"
  shift
  section "$label"
  if "$@"; then
    pass "$label"
  else
    fail "$label"
  fi
}

expect_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1"
    return 1
  }
}

build_plugins() {
  bash "$PLUGIN_ROOT/build/build.sh"
}

is_expected_executable() {
  local rel="$1"
  case "$rel" in
    bin/*|*/bin/*|*.sh|*.gates.sh|*.next-task.sh) return 0 ;;
    *) return 1 ;;
  esac
}

audit_artifact_modes() {
  local root rel bad_file file
  bad_file="$STAGE_DIR/executable-non-scripts.txt"
  : > "$bad_file"

  for root in "$PLUGIN_ROOT/dist/claude" "$PLUGIN_ROOT/dist/codex"; do
    [ -d "$root" ] || { echo "missing dist directory: $root"; return 1; }
    while IFS= read -r -d '' file; do
      rel="${file#"$root/"}"
      if ! is_expected_executable "$rel"; then
        printf '%s\n' "$root/$rel" >> "$bad_file"
      fi
    done < <(find "$root" -type f -perm -111 -print0)
  done

  if [ -s "$bad_file" ]; then
    echo "executable files without a release reason:"
    sed 's/^/  - /' "$bad_file"
    return 1
  fi
  return 0
}

audit_text_lf() {
  local root file bad_file cr
  cr=$(printf '\r')
  bad_file="$STAGE_DIR/crlf-text-files.txt"
  : > "$bad_file"

  for root in "$PLUGIN_ROOT/dist/claude" "$PLUGIN_ROOT/dist/codex"; do
    [ -d "$root" ] || { echo "missing dist directory: $root"; return 1; }
    while IFS= read -r -d '' file; do
      LC_ALL=C grep -Iq . "$file" 2>/dev/null || continue
      if LC_ALL=C grep -q "$cr" "$file" 2>/dev/null; then
        printf '%s\n' "$file" >> "$bad_file"
      fi
    done < <(find "$root" -type f -print0)
  done

  if [ -s "$bad_file" ]; then
    echo "CRLF found in release text files:"
    sed 's/^/  - /' "$bad_file"
    return 1
  fi
  return 0
}

validate_claude_plugin() {
  expect_command claude || return 1
  claude plugin validate "$REPO_ROOT" >/dev/null
  claude plugin validate "$PLUGIN_ROOT/dist/claude" >/dev/null
}

smoke_codex_plugin_install() {
  local home log
  expect_command codex || return 1
  home="$STAGE_DIR/codex-home"
  log="$STAGE_DIR/codex-plugin-smoke.log"
  mkdir -p "$home"
  if ! CODEX_HOME="$home" codex plugin marketplace add "$REPO_ROOT" --json >"$log" 2>&1; then
    cat "$log"
    return 1
  fi
  if ! CODEX_HOME="$home" codex plugin add cosherpa@cosherpa --json >>"$log" 2>&1; then
    cat "$log"
    return 1
  fi
}

smoke_scratch_init() {
  local project
  project="$STAGE_DIR/project"
  mkdir -p "$project"
  (
    cd "$project" || exit 1
    CLAUDE_SKILLS_DIR="$STAGE_DIR/claude-skills" \
      CODEX_SKILLS_DIR="$STAGE_DIR/codex-skills" \
      CODEX_PROMPTS_DIR="$STAGE_DIR/codex-prompts" \
      COSHERPA_SKILL_BACKUP_DIR="$STAGE_DIR/skill-backups" \
      "$PLUGIN_ROOT/dist/codex/bin/cosherpa-init" >/dev/null
  ) || return 1

  [ -f "$project/AGENTS.md" ] || { echo "scratch init did not create AGENTS.md"; return 1; }
  [ -f "$project/workflows/scripts/diagnose.sh" ] || { echo "scratch init did not create diagnose.sh"; return 1; }
  [ -f "$project/workflows/.cosherpa/status" ] || { echo "scratch init did not write status"; return 1; }
}

check_template_clean() {
  bash "$WORKFLOW_ROOT/scripts/template-clean-check.sh"
}

json_version() {
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
}

audit_release_metadata() {
  local claude_version codex_version init_version bad_file stale_repo_name old_plugin_name
  bad_file="$STAGE_DIR/release-metadata.txt"
  stale_repo_name="$(printf '%s_%s_%s' project template mpfcg)"
  old_plugin_name="$(printf '%s%s' iron man)"
  : > "$bad_file"

  if [ ! -f "$REPO_ROOT/LICENSE" ] && [ ! -f "$REPO_ROOT/LICENSE.md" ]; then
    echo "missing LICENSE file while plugin manifests declare a license" >> "$bad_file"
  fi

  claude_version=$(json_version "$PLUGIN_ROOT/platform/claude/plugin.json")
  codex_version=$(json_version "$PLUGIN_ROOT/platform/codex/plugin.json")
  init_version=$(sed -n 's/.*echo "version=\([^"]*\)".*/\1/p' "$PLUGIN_ROOT/src/bin/cosherpa-init" | head -1)
  if [ -z "$claude_version" ] || [ -z "$codex_version" ] || [ -z "$init_version" ]; then
    echo "could not read all release versions" >> "$bad_file"
  elif [ "$claude_version" != "$codex_version" ] || [ "$claude_version" != "$init_version" ]; then
    echo "version mismatch: claude=$claude_version codex=$codex_version init=$init_version" >> "$bad_file"
  fi

  if grep -R "$stale_repo_name" \
    "$REPO_ROOT/README.md" \
    "$REPO_ROOT/Workflow_Guideline_v1.html" \
    "$REPO_ROOT/.claude-plugin/marketplace.json" \
    "$REPO_ROOT/.agents/plugins/marketplace.json" \
    "$PLUGIN_ROOT/platform" \
    "$PLUGIN_ROOT/dist" >/dev/null 2>&1; then
    echo "stale repository name remains: $stale_repo_name" >> "$bad_file"
  fi

  if grep -R "$old_plugin_name" \
    "$REPO_ROOT/README.md" \
    "$REPO_ROOT/Workflow_Guideline_v1.html" \
    "$REPO_ROOT/.claude-plugin/marketplace.json" \
    "$REPO_ROOT/.agents/plugins/marketplace.json" \
    "$PLUGIN_ROOT/platform" \
    "$PLUGIN_ROOT/src" \
    "$PLUGIN_ROOT/dist" >/dev/null 2>&1; then
    echo "old plugin name remains in release surface: $old_plugin_name" >> "$bad_file"
  fi

  if [ -s "$bad_file" ]; then
    sed 's/^/  - /' "$bad_file"
    return 1
  fi
  return 0
}

echo "=== cosherpa release check ==="
echo "repo: $REPO_ROOT"

run_checked "Regenerate plugin dist" build_plugins
run_checked "Audit artifact executable modes" audit_artifact_modes
run_checked "Audit release text LF endings" audit_text_lf
run_checked "Validate Claude marketplace and plugin manifests" validate_claude_plugin
run_checked "Smoke Codex marketplace add + plugin add" smoke_codex_plugin_install
run_checked "Smoke scratch cosherpa-init" smoke_scratch_init
run_checked "Check template is clean for copy/distribution" check_template_clean
run_checked "Audit release metadata" audit_release_metadata

echo
if [ "$PASS" = true ]; then
  echo "[OK] release-check passed"
  exit 0
fi

echo "[FAIL] release-check found release blockers"
exit 1
