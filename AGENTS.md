# AGENTS.md — Project context & rules

Entry point for Codex/GPT (Claude also reads `CLAUDE.md`). This repo runs a two-model flow
(**Claude = planning+implementation / GPT = implementation**) on the **FCG** harness.

- The **user drives** the slash-command sequence; skills self-trigger from their own descriptions.
- Full workflow (human reference): `README.md`. FCG mechanics: `docs/fcg-system.md`.

> Fill the two sections below per project — this is the context skills cannot infer, and it
> loads every session, so keep it tight and current.

---

## Architecture
- 

## Context
- 

---

## Agent-skills configuration (load-bearing — paths the engineering skills rely on)

- **Issue tracker = local markdown.** PRDs in `docs/prd/PRD.md`; issues in `docs/issues/<NNN>-<slug>.md`
  (numbered from `001`); triage state = a `Status:` line near the top of each issue file.
- **Triage roles:** `needs-triage` / `needs-info` / `ready-for-agent` / `ready-for-human` / `wontfix`.
- **Domain docs = single-context:** one `CONTEXT.md` at repo root + `docs/adr/`.
- **Phase 1→2 bridge:** `/fcg-goal` reads `docs/issues/*.md` (or `docs/prd/PRD.md`) and writes
  `goals/<n>-<name>.{md,gates.sh,next-task.sh}` contracts.
- **FCG invariants:** gates are immutable (fix code, not gates); `.state/` is gitignored;
  in loop mode never terminate early (log to `blockers.md` after 3 stalled rounds).

## Spec authority (which doc wins on conflict)

- **Current contract = only what `docs/spec/INDEX.md` lists** (schema, API contract, public
  types in `docs/spec/`). This is the single source of truth for implementation. On any
  conflict, it overrides PRD and ADRs.
- **Read order for implementation:** `AGENTS.md` → `CONTEXT.md` (glossary) →
  `docs/spec/INDEX.md` → the contract docs it points to → latest accepted ADRs → code & tests.
- **PRD (`docs/prd/`) = original intent, not current state.** Don't treat it as the live spec.
- **ADR (`docs/adr/`) = decision history, one decision per file.** A `superseded by ADR-NNNN`
  (frontmatter + top banner) ADR is history, not a basis for implementation. ADRs stay in
  place — don't archive to read them out of context.

## Phase 1 elicitation (planning gate)

- **Surface load-bearing choices before freezing the spec.** Persistence, delivery shape
  (service / library / CLI / UI), and stack are decisions the whole plan rests on — state them to
  the user **explicitly, with the trade-off**, never silently default. A silently-defaulted
  load-bearing choice traps a user who didn't know to object; they discover the wrong one only at
  build time. `to-spec` will not freeze a contract while such a choice is unresolved.
- **Ask in plain words, encode in precise rules.** With a non-developer, translate jargon into the
  decision behind it: not "is this an invariant?" but "if this changes, must something else change
  too?"; not "what's the authorization model?" but "who may do this, and who must be blocked?" Then
  translate the plain answer back into the precise contract term.

## Project-specific skills

`.claude/skills/` = skills only this project needs (global skills live in `~/.claude`, `~/.codex`).
Add one only when a pattern has proven to repeat — don't auto-generate agent/skill rosters
(context bloat hurts performance). Encode tailoring above and in `goals/<n>-*.gates.sh` instead.
