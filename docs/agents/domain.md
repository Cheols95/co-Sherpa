# Domain docs layout (for engineering skills)

> Single source of truth: **`AGENTS.md` → "Agent-skills configuration" → "Domain docs"**
> (auto-loaded each session — that's what grill-with-docs / improve-codebase-architecture / tdd
> actually use). This file is a pointer + ready path-slot for skills that look it up by path
> (e.g. zoom-out / diagnose) when installed.

- **Single-context repo** (not a monorepo CONTEXT-MAP layout).
- **Domain glossary / model:** one `CONTEXT.md` at repo root.
  (Created lazily by `/grill-with-docs` in Phase 1 — may not exist yet on a fresh template.)
- **Decisions:** `docs/adr/` (one ADR per decision).

Skills must use `CONTEXT.md` vocabulary for the domain and not re-litigate `docs/adr/` decisions.
