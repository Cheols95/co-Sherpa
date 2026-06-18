---
name: migration
description: Onboard an existing brownfield codebase into the ironman harness. Use when the user invokes '/ironman:migration', after '/ironman:init' on an existing project, or when AGENTS.md Architecture/Context and CONTEXT.md need to be filled from code and user intent.
---

# migration — brownfield onboarding

Convert an existing codebase into useful ironman project context. This skill writes harness content; it
does not commit.

## Preconditions

- The current directory is a git repo. If not, ask before running `git init`.
- ironman structure exists. If `workflows/scripts/diagnose.sh` or `workflows/goals/AGENTS.md` is missing, run
  `/ironman:init` first.
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
   - seed accepted tradeoff ADRs in `workflows/docs/adr/`
4. **REVIEW.** Run an independent review pass over the generated harness. If a subagent is available,
   use one reviewer that did not author the docs. Otherwise perform an explicit self-review and report
   residual uncertainty.
5. **GATE.** Walk the key decisions back to the user. Completion means the harness documents describe
   the project, not the migration process, and no dangerous unknown is silently filled.

Use `workflows/skills/concept/CONTEXT-FORMAT.md` and `workflows/skills/concept/ADR-FORMAT.md` for formatting. Do not create a
new document taxonomy.
