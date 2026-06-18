#!/usr/bin/env bash
# build.sh -- regenerate Claude and Codex ironman plugins from shared sources.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$WORKFLOW_ROOT/.." && pwd)"
SRC="$PLUGIN_ROOT/src"
CLAUDE_OUT="$PLUGIN_ROOT/dist/claude"
CODEX_OUT="$PLUGIN_ROOT/dist/codex"

. "$PLUGIN_ROOT/build/package-lib.sh"

echo "=== build: claude plugin ==="
rm -rf "$CLAUDE_OUT"
mkdir -p "$CLAUDE_OUT/.claude-plugin" "$CLAUDE_OUT/skills" "$CLAUDE_OUT/bin"
cp "$PLUGIN_ROOT/platform/claude/plugin.json" "$CLAUDE_OUT/.claude-plugin/plugin.json"
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
package_copy_workflow_assets "$CLAUDE_OUT"
package_normalize_release_tree "$CLAUDE_OUT"

echo "=== build: codex plugin ==="
rm -rf "$CODEX_OUT"
mkdir -p "$CODEX_OUT/.codex-plugin" "$CODEX_OUT/skills" "$CODEX_OUT/bin"
cp "$PLUGIN_ROOT/platform/codex/plugin.json" "$CODEX_OUT/.codex-plugin/plugin.json"
cp -R "$SRC/skills/." "$CODEX_OUT/skills/"
cp -R "$PLUGIN_ROOT/platform/codex/skills/." "$CODEX_OUT/skills/"
cp -R "$SRC/bin/." "$CODEX_OUT/bin/"
chmod +x "$CODEX_OUT/bin/"* 2>/dev/null || true
package_copy_workflow_assets "$CODEX_OUT"
package_normalize_release_tree "$CODEX_OUT"

echo "=== done: workflows/plugin/dist/{claude,codex} regenerated ==="
