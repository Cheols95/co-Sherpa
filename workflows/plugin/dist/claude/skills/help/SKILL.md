---
name: help
description: Explain the co-Sherpa workflow, inspect the current project state, and recommend the next command. Use when the user invokes '/cosherpa:help', asks what to do next, or asks how concept/freeze/build/init/migration fit together.
---

# help — route the current co-Sherpa state

Answer in the user's language. Prefer a short state diagnosis and one next command over a catalog dump.

## State Check

If the project has `workflows/scripts/diagnose.sh`, run:

```bash
bash workflows/scripts/diagnose.sh
```

Also inspect Phase 1 state directly:

- `workflows/docs/design/checklist.md`
- `workflows/docs/prd/PRD.md`
- `workflows/docs/spec/INDEX.md`
- `workflows/docs/issues/*.md`
- `workflows/goals/` real numbered goals versus only `0-example`

## Routing

- No co-Sherpa structure -> `/cosherpa:init`
- Brownfield codebase with empty `AGENTS.md` Architecture/Context -> `/cosherpa:migration`
- Open concept checklist -> `/concept`
- Closed concept checklist and no freeze outputs -> `/freeze`
- Issues exist but no real goals -> `/build`
- Active failing goal -> `/build`
- All goals done and open findings exist -> `/cycle`, then `/build workflows/cycles/<file>.md`
- Session handoff needed -> `/handoff`

For general workflow questions, ground the answer in `Workflow_Guideline_v1.html`, `AGENTS.md`, and
the relevant skill descriptions. Keep the daily command surface clear:

- Plugin lifecycle: `/cosherpa:init`, `/cosherpa:help`, `/cosherpa:migration`
- Daily workflow: `/concept`, `/freeze`, `/build`, `/finding`, `/cycle`, `/handoff`, `/roadmap`,
  `/prototype`, `/spec-sync`, `/improve-codebase-architecture`
