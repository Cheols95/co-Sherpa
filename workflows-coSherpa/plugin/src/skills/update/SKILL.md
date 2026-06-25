---
name: update
description: Check for the latest co-Sherpa release, update the plugin when it is behind, and re-sync this project. Compares the installed plugin version with the latest published version; if a newer one exists, updates via the host plugin manager (restart required to apply), then syncs the local workflows-coSherpa/ harness and daily skills. Use when the user invokes '/cosherpa:update', asks to update/upgrade co-Sherpa, or to check for and pull the newest version.
---

# update — check for the latest co-Sherpa, update, and re-sync this project

Answer in the user's language. Run the steps in order and **decide between step 2 and step 3 by
reading the versions printed in step 1** — do not run both.

The host loads new plugin code only after a restart/reload — `claude plugin update` itself says
"restart required to apply". So when this skill updates the plugin, it cannot use the new code in the
same session: it updates, then asks the user to restart and re-run `/cosherpa:update`. The only manual
step in the whole flow is that one restart.

## 1. Read installed, harness, and latest versions

This block is self-contained (it resolves `cosherpa-init` the same way as `/cosherpa:init`: Claude
Code puts the plugin `bin/` on `PATH` and sets `CLAUDE_PLUGIN_ROOT`; Codex does neither). Run it and
read the three versions it prints.

```bash
BIN=""
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init" ] && BIN="$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init"
[ -n "$BIN" ] || BIN="$(command -v cosherpa-init 2>/dev/null || true)"
[ -n "$BIN" ] || BIN="$(find "$HOME/.codex/plugins" "$HOME/.claude/plugins" -type f -name cosherpa-init -path '*/bin/*' 2>/dev/null | head -1)"
installed="$([ -n "$BIN" ] && bash "$BIN" --version 2>/dev/null | sed -n 's/^version=//p')"
harness="$([ -f workflows-coSherpa/.cosherpa/status ] && sed -n 's/^version=//p' workflows-coSherpa/.cosherpa/status)"
url="https://raw.githubusercontent.com/Cheols95/co-Sherpa/main/workflows-coSherpa/plugin/dist/claude/.claude-plugin/plugin.json"
latest="$( (curl -fsSL "$url" 2>/dev/null || wget -qO- "$url" 2>/dev/null) | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 )"
echo "installed plugin : ${installed:-unknown (is the plugin installed?)}"
echo "project harness  : ${harness:-none (run /cosherpa:init first)}"
echo "latest published : ${latest:-unknown (offline — skip to step 3 and just re-sync)}"
```

Now decide (semver compare of `installed` vs `latest`):

- `latest` is **newer** than `installed` -> **step 2** (update the plugin), then stop.
- `installed == latest`, or `latest` is unknown/offline -> **step 3** (the plugin is current; sync the project).

## 2. Plugin is behind → update it in the host, then stop

Detect the host and update the plugin. On failure, print the commands so the user can run them by
hand. (Refreshing the marketplace alone is not enough — the plugin must be updated and reloaded.)

```bash
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace update cosherpa && claude plugin update cosherpa \
    || echo "auto-update failed — run by hand: claude plugin marketplace update cosherpa && claude plugin update cosherpa"
elif command -v codex >/dev/null 2>&1; then
  codex plugin marketplace upgrade cosherpa && codex plugin add cosherpa@cosherpa \
    || echo "auto-update failed — run by hand: codex plugin marketplace upgrade cosherpa && codex plugin add cosherpa@cosherpa"
else
  echo "no host plugin CLI found — update the cosherpa plugin from your host's plugin manager"
fi
```

The new plugin applies only after a restart. Tell the user (fill in the version from step 1):

> Updated the cosherpa plugin to `<latest>`. Restart the session — or run `/reload-plugins` in Claude
> Code — then run `/cosherpa:update` once more to sync this project to the new version.

**Stop here.** Do not run step 3 in this session: the old plugin is still loaded, so syncing now would
pin the project to the old version.

## 3. Plugin already current → re-sync the project harness

The plugin is up to date (or the latest is unknown). Bring the project to the installed plugin: run
`cosherpa-init` from the project root. It re-copies harness assets, reinstalls the daily Claude and
Codex skills, regenerates Codex shims, and rewrites `.cosherpa/status`. Existing `.gitignore` rules
and your `AGENTS.md` Architecture/Context are preserved.

```bash
BIN=""
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init" ] && BIN="$CLAUDE_PLUGIN_ROOT/bin/cosherpa-init"
[ -n "$BIN" ] || BIN="$(command -v cosherpa-init 2>/dev/null || true)"
[ -n "$BIN" ] || BIN="$(find "$HOME/.codex/plugins" "$HOME/.claude/plugins" -type f -name cosherpa-init -path '*/bin/*' 2>/dev/null | head -1)"
[ -n "$BIN" ] && bash "$BIN" || echo "could not locate cosherpa-init; is the cosherpa plugin installed?" >&2
[ -f workflows-coSherpa/.cosherpa/status ] && cat workflows-coSherpa/.cosherpa/status
```

Report the outcome: already on the latest version and synced, or what the sync changed. If
`cosherpa-init` cannot be found, the plugin is not installed for this host — do not hand-copy files;
point the user to install/update it from the host plugin manager.
