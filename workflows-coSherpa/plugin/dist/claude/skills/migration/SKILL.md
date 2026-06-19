---
name: migration
description: Onboard an existing brownfield codebase into the co-Sherpa harness. Use when the user invokes '/cosherpa:migration', after '/cosherpa:init' on an existing project, or when AGENTS.md Architecture/Context and CONTEXT.md need to be filled from code and user intent.
---

# migration — brownfield onboarding

Convert an existing codebase into useful co-Sherpa project context. This skill writes harness content; it
does not commit.

## Preconditions

- The current directory is a git repo. If not, ask before running `git init`.
- co-Sherpa structure exists. If `workflows-coSherpa/scripts/diagnose.sh` or
  `workflows-coSherpa/goals/AGENTS.md` is missing, run `/cosherpa:init` first.
  Do not treat a pre-existing generic workflow directory as co-Sherpa ownership.
- Existing code is present. For a greenfield project, route to `/concept` instead.

## Process

1. **SCAN.** Read the repo shape, existing docs, build/test files, modules, domain entities, security
   surfaces, external dependencies, and recent git history. Build a ledger of load-bearing facts and
   unknowns.
2. **ELICIT.** Infer what code can prove. Ask the user only for facts where being wrong is dangerous:
   business model, domain invariants, authorization/security policy, irreversible external effects,
   and intentional tradeoffs not visible in code. Every ledger item must close as confirmed,
   asked-answered, or N/A with a reason.
3. **GENERATE.** Update only the lean FCG harness:
   - fill `AGENTS.md` §Architecture and §Context
   - create/update root `CONTEXT.md`
   - seed accepted tradeoff ADRs in `workflows-coSherpa/docs/adr/`
4. **REVIEW.** Run an independent review pass over the generated harness. If a subagent is available,
   use one reviewer that did not author the docs. Otherwise perform an explicit self-review and report
   residual uncertainty.
5. **GATE.** Walk the key decisions back to the user. Completion means the harness documents describe
   the project, not the migration process, and no dangerous unknown is silently filled.

Use `workflows-coSherpa/skills/concept/CONTEXT-FORMAT.md` and
`workflows-coSherpa/skills/concept/ADR-FORMAT.md` for formatting. Do not create a new document
taxonomy.
