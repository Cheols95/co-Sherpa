---
name: update
description: Update co-Sherpa to the latest and re-sync this project. Re-syncs the local workflows-coSherpa/ harness and the machine-global daily skills to the installed plugin, and shows how to pull a newer plugin from the marketplace. Use when the user invokes '/cosherpa:update', asks to update/upgrade co-Sherpa, or wants the newest workflow after the author pushed a release.
---

# update — pull the latest co-Sherpa and re-sync this project

Answer in the user's language. This command does two things, in order: (1) re-sync the project's
`workflows-coSherpa/` harness and the machine-global daily skills to the **currently installed**
plugin, then (2) tell the user how to fetch a **newer** plugin from the marketplace when one exists.

This skill runs from the plugin that is already installed — it cannot replace the plugin itself.
Only the host's plugin manager (plus a reload) can do that. So the reliable update flow is: refresh
the plugin in the host, reload, then run this command to sync the project.

## 1. Show the installed version

```bash
[ -f workflows-coSherpa/.cosherpa/status ] && cat workflows-coSherpa/.cosherpa/status || echo "no co-Sherpa harness here yet — run /cosherpa:init"
```

## 2. Re-sync the harness from the installed plugin

Resolve the bundled `cosherpa-init` executable (same discovery as `/cosherpa:init`: Claude Code puts
the plugin `bin/` on `PATH` and sets `CLAUDE_PLUGIN_ROOT`; Codex does neither) and run it **from the
project root**. It re-copies the harness assets into `workflows-coSherpa/`, reinstalls the daily
Claude and Codex skills, regenerates Codex shims, and rewrites `.cosherpa/status` with the synced
version. Existing `.gitignore` rules and your `AGENTS.md` Architecture/Context are preserved.

```bash
BIN=""
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init" ] && BIN="$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init"
[ -n "$BIN" ] || BIN="$(command -v cosherpa-init 2>/dev/null || true)"
[ -n "$BIN" ] || BIN="$(find "$HOME/.codex/plugins" "$HOME/.claude/plugins" -type f -name cosherpa-init -path '*/bin/*' 2>/dev/null | head -1)"
[ -n "$BIN" ] && bash "$BIN" || echo "could not locate cosherpa-init; is the cosherpa plugin installed?" >&2
```

Then show the version again so the user sees the delta:

```bash
[ -f workflows-coSherpa/.cosherpa/status ] && cat workflows-coSherpa/.cosherpa/status
```

If `cosherpa-init` cannot be found, the plugin is not installed for this host — point the user to the
host update steps below. Do not hand-copy the harness files.

## 3. Fetch a newer plugin when the installed one is already current

Step 2 only syncs to the plugin installed right now. If the author pushed a newer release, the user
must update the plugin in the host first, then reload, then re-run `/cosherpa:update`. These are host
commands the user runs — surface them, do not try to run them as a shell script.

**Claude Code:**

```text
/plugin marketplace update cosherpa
/plugin install cosherpa@cosherpa
/reload-plugins
```

(`claude plugin marketplace update cosherpa` then `claude plugin update cosherpa` are the
non-interactive CLI equivalents. Refreshing the marketplace alone is not enough — the plugin must be
reinstalled/updated and reloaded.)

**Codex:**

```bash
codex plugin marketplace upgrade cosherpa
codex plugin add cosherpa@cosherpa
```

Then start a fresh Codex session.

After the host has the new plugin loaded, run `/cosherpa:update` again so step 2 syncs the project to
the new version.
