---
name: migration
description: Onboard an existing brownfield codebase into the co-Sherpa harness. Use when the user invokes '/cosherpa:migration', after '/cosherpa:init' on an existing project, or when AGENTS.md Architecture/Context and CONTEXT.md need to be filled from code and user intent.
---

# migration — brownfield onboarding v2

Convert an existing codebase into useful co-Sherpa project context. This skill writes project context and
a migration report; it does not commit, does not modify application code, and does not create official
PRD/spec/issue/ADR documents.

## Preconditions

- The current directory is a git repo. If not, ask before running `git init`.
- co-Sherpa structure exists. If `workflows-coSherpa/scripts/diagnose.sh` or
  `workflows-coSherpa/goals/AGENTS.md` is missing, run `/cosherpa:init` first.
  Do not treat a pre-existing generic workflow directory as co-Sherpa ownership.
- Existing code is present. For a greenfield project, route to `/concept` instead.

## Outputs

Allowed writes:

- `AGENTS.md` §Architecture and §Context, only for concise current project facts.
- Root `CONTEXT.md`, only for domain terms that are current and unambiguous.
- `workflows-coSherpa/docs/concept/migration-report.md`, the candidate ledger and next-step guide.

Forbidden writes during migration:

- Do not create or edit `workflows-coSherpa/docs/prd/PRD.md`.
- Do not create or edit `workflows-coSherpa/docs/spec/*`.
- Do not create or edit `workflows-coSherpa/docs/issues/*`.
- Do not create or edit `workflows-coSherpa/docs/adr/*`, including "seed" ADRs.
- Do not modify application source, tests, build scripts, package metadata, or user docs outside the
  allowed harness outputs.

If a user explicitly asks to write an ADR during the same conversation, stop migration and treat that as a
separate direct ADR request. Otherwise ADRs are written from `/concept` after the relevant decision is
closed.

## Process

1. **SCAN.** Read the repo shape, existing docs, build/test files, package/dependency manifests, entry
   points, modules, domain entities, security/authorization surfaces, persistence, external integrations,
   deployment/runtime hints, and recent git history. Existing documents are material, not authority.
2. **CLASSIFY.** Build a migration ledger. Every discovered document, load-bearing code fact, conflict,
   and unknown gets a stable id and one disposition:
   - `context-term` — domain term candidate for `CONTEXT.md`.
   - `architecture-context` — concise current structure/context for `AGENTS.md`.
   - `prd-candidate` — feature/product intent that must go through `/concept` before `/freeze`.
   - `spec-candidate` — observed API/schema/type/config contract candidate that must go through
     `/concept` before official spec unless the user makes a separate explicit spec-maintenance request.
   - `adr-candidate` — important historical tradeoff candidate; never write the ADR in migration.
   - `finding-candidate` — bug, debt, or future work candidate.
   - `stale-or-superseded` — old material that should not guide current work.
   - `ignore-nonmaterial` — files with no workflow relevance, with a short reason.
   - `question-required` — dangerous unknown that must be asked before writing project context.
3. **ELICIT.** Infer what code can prove. Ask the user only for facts where being wrong is dangerous:
   business model, current intent, stale-vs-current document authority, domain invariants,
   authorization/security policy, irreversible external effects, and intentional tradeoffs not visible in
   code. Questions must name the source, the conflict/unknown, the consequence of guessing wrong, and a
   recommended answer with an open "something else" option when the user owns the domain decision.
4. **GENERATE.** Update only allowed outputs:
   - write concise current facts to `AGENTS.md` §Architecture and §Context;
   - write only unambiguous current terms to `CONTEXT.md`;
   - write the full ledger and routing recommendations to
     `workflows-coSherpa/docs/concept/migration-report.md`.
5. **ROUTE.** For each candidate, give a concrete next command:
   - PRD/spec candidates: `/concept workflows-coSherpa/docs/concept/migration-report.md 의 <candidate-id>를 기준으로 결정표면을 닫아줘`
   - ADR candidates: "review this candidate in `/concept`; write an ADR only after the user approves the
     decision wording."
   - finding candidates: keep in the report unless the user asks to promote them with `/finding`.
6. **REVIEW.** Run an independent review pass over the generated harness and report. If a subagent is
   available, use one reviewer that did not author the docs. Otherwise perform an explicit self-review.
   The review checks over-claiming, missing dispositions, unapproved ADR/spec/PRD creation, and accidental
   application-code edits.
7. **GATE.** Walk the written project context, unresolved questions, and recommended `/concept` queue back
   to the user. Completion means every ledger item has a disposition and no dangerous unknown is silently
   filled.

## Migration Report Format

Write `workflows-coSherpa/docs/concept/migration-report.md` with these sections:

```md
# Migration Report

## Project Snapshot
- purpose:
- primary users:
- runtime/build/test:
- architecture summary:
- known risks:

## Source Inventory
| id | path | kind | current/stale/unknown | evidence |
|---|---|---|---|---|

## Candidate Ledger
| id | disposition | source | claim | evidence | confidence | next action |
|---|---|---|---|---|---|---|

## User Confirmation Questions
| id | question | why it matters | recommended default |
|---|---|---|---|

## Recommended Concept Queue
| order | candidate id | reason | command |
|---|---|---|---|

## Written Changes
- `AGENTS.md`:
- `CONTEXT.md`:

## Not Written During Migration
- PRD/spec/issues/ADR files:
- application source/test/build files:

## Review Notes
- over-claiming check:
- missing-disposition check:
- residual uncertainty:
```

Use `workflows-coSherpa/skills/concept/CONTEXT-FORMAT.md` and
`workflows-coSherpa/skills/concept/ADR-FORMAT.md` for formatting. Do not create a new document
taxonomy.
