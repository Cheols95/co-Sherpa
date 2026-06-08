# CLAUDE.md — Claude entry point

**Read `AGENTS.md`** for this project's architecture, context, and the load-bearing Agent-skills configuration (issue-tracker paths, triage roles, FCG bridge). Don't duplicate it here.

Claude-specific notes:

- **Phase 1 planning is Claude's primary role** — discuss actively to sharpen requirements
  (`/grill-with-docs` → `/to-prd` → `/to-spec` → `/to-issues`). Claude can also run the FCG implementation
  loop (`/fcg-goal` etc.) when useful; GPT is primary for high-volume coding.
- Run `/handoff` before switching model/session.
- Skills auto-trigger from their descriptions — the user drives the sequence; you don't need to
  recite the workflow. Full workflow lives in `README.md`.

_(Add Claude-only project notes below, if any.)_
