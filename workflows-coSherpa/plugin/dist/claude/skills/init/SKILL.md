---
name: init
description: Initialize or update the co-Sherpa workflow harness in the current project. Use when the user invokes '/cosherpa:init', asks to install co-Sherpa into a repo, or wants to sync/update the workflow after a plugin update.
disable-model-invocation: true
allowed-tools: Bash
---

# init — install or sync co-Sherpa

Run the bundled `cosherpa-init` executable **from the project root** (its working directory becomes
the install target). Resolve the executable's path first — do not rely on a bare command name,
because not every host puts the plugin `bin/` on `PATH`: Claude Code does, Codex does not.

```bash
# Resolve cosherpa-init, then run it from the project root.
# Claude Code exposes the plugin bin on PATH and sets CLAUDE_PLUGIN_ROOT; Codex does
# neither, so fall back to the installed plugin's bin. Run via `bash` so it works even
# if the host dropped the file's execute bit when it copied the plugin.
BIN=""
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init" ] && BIN="$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init"
[ -n "$BIN" ] || BIN="$(command -v cosherpa-init 2>/dev/null || true)"
[ -n "$BIN" ] || BIN="$(find "$HOME/.codex/plugins" "$HOME/.claude/plugins" -type f -name cosherpa-init -path '*/bin/*' 2>/dev/null | head -1)"
[ -n "$BIN" ] && bash "$BIN" || echo "could not locate cosherpa-init; is the cosherpa plugin installed?" >&2
```

If no `cosherpa-init` can be found, the plugin is not installed for this host — ask the user to
install or reinstall the cosherpa plugin. Do not hand-copy the harness files.

`cosherpa-init` is both the first-time initializer and the update sync. It copies the harness assets
into `workflows-coSherpa/`, installs/updates the machine-global daily skills for Claude and Codex,
regenerates Codex slash shims, and reports the next command.

Existing `.gitignore` files are preserved: co-Sherpa appends its runtime/generated ignore rules if
they are missing rather than replacing the user's project-specific rules.

Routes:

- greenfield project: `/concept`
- existing codebase without co-Sherpa context: `/cosherpa:migration`
- existing co-Sherpa project: continue with `/concept`, `/freeze`, or `/build` as appropriate
