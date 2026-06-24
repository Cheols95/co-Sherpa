---
name: help
description: Explain the co-Sherpa workflow, inspect the current project state, and recommend the next command. Use when the user invokes '/cosherpa:help', asks what to do next, or asks how concept/freeze/build/init/migration fit together.
---

# help — route the current co-Sherpa state

Answer in the user's language. Prefer a short state diagnosis and one next command over a catalog dump.

## State Check

If the project has `workflows-coSherpa/scripts/diagnose.sh`, run:

```bash
bash workflows-coSherpa/scripts/diagnose.sh
```

Also inspect Phase 1 state directly:

- `workflows-coSherpa/docs/concept/checklist.md`
- `workflows-coSherpa/docs/concept/migration-report.md`
- `workflows-coSherpa/docs/prd/PRD.md`
- `workflows-coSherpa/docs/spec/INDEX.md`
- `workflows-coSherpa/docs/issues/*.md`
- `workflows-coSherpa/goals/` real numbered goals versus only `0-example`

## Routing

- No co-Sherpa structure -> `/cosherpa:init`
- Brownfield codebase with empty `AGENTS.md` Architecture/Context -> `/cosherpa:migration`
- Migration report with recommended concept queue -> `/concept workflows-coSherpa/docs/concept/migration-report.md 의 <candidate-id>를 기준으로 결정 체크리스트를 닫아줘`
- Open concept checklist -> `/concept`
- Closed concept checklist and no freeze outputs -> `/freeze`
- Issues exist but no real goals -> `/build`
- Active failing goal -> `/build`
- All goals done and open findings exist -> `/cycle`, then `/build workflows-coSherpa/cycles/<file>.md`
- Session handoff needed -> `/handoff`

For general workflow questions, ground the answer in `Workflow_Guideline_v2.html`, `AGENTS.md`, and
the relevant skill descriptions. Keep the daily command surface clear:

- Plugin lifecycle: `/cosherpa:init`, `/cosherpa:help`, `/cosherpa:migration`
- Daily workflow: `/concept`, `/freeze`, `/build`, `/finding`, `/cycle`, `/handoff`, `/roadmap`,
  `/prototype`, `/spec-sync`, `/improve-codebase-architecture`
