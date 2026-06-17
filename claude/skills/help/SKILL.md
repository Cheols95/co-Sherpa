---
name: help
description: Explain the ironman workflow, inspect the current project state, and recommend the next command. Use when the user invokes '/ironman:help', asks what to do next, or asks how concept/freeze/build/init/migration fit together.
---

# help — route the current ironman state

Answer in the user's language. Prefer a short state diagnosis and one next command over a catalog dump.

## State Check

If the project has `scripts/diagnose.sh`, run:

```bash
bash scripts/diagnose.sh
```

Also inspect Phase 1 state directly:

- `docs/design/checklist.md`
- `docs/prd/PRD.md`
- `docs/spec/INDEX.md`
- `docs/issues/*.md`
- `goals/` real numbered goals versus only `0-example`

## Routing

- No ironman structure -> `/ironman:init`
- Brownfield codebase with empty `AGENTS.md` Architecture/Context -> `/ironman:migration`
- Open concept checklist -> `/concept`
- Closed concept checklist and no freeze outputs -> `/freeze`
- Issues exist but no real goals -> `/build`
- Active failing goal -> `/build`
- All goals done and open findings exist -> `/cycle`, then `/build cycles/<file>.md`
- Session handoff needed -> `/handoff`

For general workflow questions, ground the answer in `Workflow_Guideline_v1.html`, `AGENTS.md`, and
the relevant skill descriptions. Keep the daily command surface clear:

- Plugin lifecycle: `/ironman:init`, `/ironman:help`, `/ironman:migration`
- Daily workflow: `/concept`, `/freeze`, `/build`, `/finding`, `/cycle`, `/handoff`, `/roadmap`,
  `/prototype`, `/spec-sync`, `/improve-codebase-architecture`
