#!/usr/bin/env bash
# build.sh -- regenerate Claude and Codex ironman plugins from shared sources.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src"
CLAUDE_OUT="$ROOT/claude"
CODEX_OUT="$ROOT/plugins/ironman"

copy_workflow_assets() {
  local dest="$1/assets/workflow"
  rm -rf "$dest"
  mkdir -p "$dest"

  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    if [[ "$line" == */ ]]; then
      [ -d "$ROOT/$line" ] || continue
      mkdir -p "$dest/$line"
      cp -R "$ROOT/$line/." "$dest/$line/"
    else
      [ -f "$ROOT/$line" ] || { echo "[FAIL] manifest path missing: $line" >&2; exit 2; }
      mkdir -p "$dest/$(dirname "$line")"
      cp "$ROOT/$line" "$dest/$line"
    fi
  done < "$ROOT/workflow-manifest.txt"

  cp -R "$ROOT/skills" "$dest/skills"
}

echo "=== build: claude plugin ==="
rm -rf "$CLAUDE_OUT"
mkdir -p "$CLAUDE_OUT/.claude-plugin" "$CLAUDE_OUT/skills" "$CLAUDE_OUT/bin"
cp "$ROOT/platform/claude/plugin.json" "$CLAUDE_OUT/.claude-plugin/plugin.json"
cp -R "$SRC/skills/." "$CLAUDE_OUT/skills/"
cp -R "$SRC/bin/." "$CLAUDE_OUT/bin/"
chmod +x "$CLAUDE_OUT/bin/"* 2>/dev/null || true
PYTHON_BIN="${PYTHON_BIN:-python3}"
"$PYTHON_BIN" - "$CLAUDE_OUT/skills/init/SKILL.md" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
if "disable-model-invocation:" not in text:
    text = text.replace("---\n\n#", "disable-model-invocation: true\nallowed-tools: Bash\n---\n\n#", 1)
path.write_text(text, encoding="utf-8")
PY
copy_workflow_assets "$CLAUDE_OUT"

echo "=== build: codex plugin ==="
rm -rf "$CODEX_OUT"
mkdir -p "$CODEX_OUT/.codex-plugin" "$CODEX_OUT/skills" "$CODEX_OUT/bin"
cp "$ROOT/platform/codex/plugin.json" "$CODEX_OUT/.codex-plugin/plugin.json"
cp -R "$SRC/skills/." "$CODEX_OUT/skills/"
cp -R "$ROOT/platform/codex/skills/." "$CODEX_OUT/skills/"
cp -R "$SRC/bin/." "$CODEX_OUT/bin/"
chmod +x "$CODEX_OUT/bin/"* 2>/dev/null || true
copy_workflow_assets "$CODEX_OUT"

echo "=== done: claude/ and plugins/ironman regenerated ==="
