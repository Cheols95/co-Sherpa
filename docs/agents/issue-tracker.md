# Issue tracker config (for engineering skills)

> Single source of truth: **`AGENTS.md` → "Agent-skills configuration"** (auto-loaded every
> session — that's what the installed to-prd / to-issues skills actually read). This file is a
> human-readable pointer and a ready path-slot for skills that look it up by path when installed
> (triage / qa). Keep it in sync with AGENTS.md.

- **Tracker = local markdown** (no GitHub/GitLab).
- **PRDs:** `docs/prd/PRD.md`
- **Issues:** `docs/issues/<NNN>-<slug>.md` (numbered from `001`)
- **Triage state:** a `Status:` line near the top of each issue file (see `triage-labels.md`).
- **Phase 1→2 bridge:** `/fcg-goal` reads `docs/issues/*.md` (or `docs/prd/PRD.md`) and writes
  `goals/<n>-<name>.{md,gates.sh,next-task.sh}` execution contracts.
