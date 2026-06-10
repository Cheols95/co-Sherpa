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
- **Issue frontmatter = machine-readable contract.** Each issue opens with YAML frontmatter carrying
  `depends: [NNN, ...]` (inline list of blocking issue ids — mirrors the prose "Blocked by" section;
  on disagreement frontmatter wins) and `risk: RISKY | MECHANICAL | NONE`. `/to-issues` emits both;
  the roadmap dashboard reads `depends:`; `/fcg-goal` mode B carries `risk:` into the goal contract.
  - **Risk heuristic (a floor, judged per slice):** `RISKY` if the slice names an explicit edge case,
    invariant, state-coordination or validation rule, **or** touches data integrity (schema/
    migration), auth/security boundaries, money, irreversible external effects, or the `docs/spec/`
    contract surface. `NONE` if it has no behavioral surface (docs/config/pure scaffold).
    `MECHANICAL` otherwise. An **omitted `risk` is unclassified, NOT mechanical** — judge at
    conversion time and bias toward stronger verification (degrade-don't-corrupt).
- **Triage roles:** `needs-triage` / `needs-info` / `ready-for-agent` / `ready-for-human` / `wontfix`.
- **Domain docs = single-context:** one `CONTEXT.md` at repo root + `docs/adr/`.
- **Phase 1→2 bridge:** `/fcg-goal` reads `docs/issues/*.md` (or `docs/prd/PRD.md`) and writes
  `goals/<n>-<name>.{md,gates.sh,next-task.sh}` contracts. On the **first** conversion it
  **replaces the `goals/0-example.*` placeholder triplet** (a teaching example, not a real
  goal; see the Bootstrap rule in `goals/AGENTS.md`) rather than leaving it beside the real
  goals. Goal `<n>` is an ordering label, not a 1:1 map to issue `NNN`; link a goal to its
  issue by slug (`goals/<n>-<slug>`).
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
- **Account the decision surface — the observable exit bar for grilling.** Before freezing, name the
  entities (a manifest), then walk four lenses over each entity and colliding pair to enumerate the
  load-bearing decisions the design is *obligated* to answer: **STRUCTURAL** (cardinality/
  composition/identity), **BEHAVIORAL** (lifecycle/concurrency/policy/edges), **TECHNICAL**
  (persistence/interface/consistency), **CONTRACT** (status·enum *sets*/uniqueness/output keys).
  Every slot must end **grounded** (the user said it, or it follows from what they said),
  **asked-and-answered**, or **deferred-tunable** (a default inside a settled mechanism, marked
  tunable). Enumerate exhaustively, ask minimally — never ask what is derivable. Grilling ends when
  no `assumed` slot survives — not when it "feels like enough".
- **Pre-freeze intent-audit (independent).** Right before `/to-spec` freezes the contract, dispatch
  one subagent that did **not** author the plan; it reads the dialogue + the decision surface and
  hunts un-grounded guesses (a slot settled silently, a disposition rubber-stamped). Each finding is
  closed by asking the user — never patched silently into a document. No subagent tooling available
  (e.g. a Codex session) → run the audit as an explicit self-review pass and surface the list to the
  user. The downstream existence of this audit is **no license for shallow grilling** — a finding
  here means the dialogue was closed too early.

## Project-specific skills

`.claude/skills/` = skills only this project needs (global skills live in `~/.claude`, `~/.codex`).
Add one only when a pattern has proven to repeat — don't auto-generate agent/skill rosters
(context bloat hurts performance). Encode tailoring above and in `goals/<n>-*.gates.sh` instead.
