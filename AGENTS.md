# AGENTS.md — Project context & rules

Entry point for Codex/GPT (Claude also reads `CLAUDE.md`). This repo runs a two-model flow
(**Claude = planning+implementation / GPT = implementation**) on the **FCG** harness.

- The **user drives** the slash-command sequence; skills self-trigger from their own descriptions.
- Full workflow (human reference): `Workflow_Guideline_v1.html`. FCG mechanics: `docs/fcg-system.md`.

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
  the roadmap dashboard reads `depends:`; `/build` mode B carries `risk:` into the goal contract.
  - **Risk heuristic (a floor, judged per slice):** `RISKY` if the slice names an explicit edge case,
    invariant, state-coordination or validation rule, **or** touches data integrity (schema/
    migration), auth/security boundaries, money, irreversible external effects, or the `docs/spec/`
    contract surface. `NONE` if it has no behavioral surface (docs/config/pure scaffold).
    `MECHANICAL` otherwise. An **omitted `risk` is unclassified, NOT mechanical** — judge at
    conversion time and bias toward stronger verification (degrade-don't-corrupt).
- **Triage roles:** `needs-triage` / `needs-info` / `ready-for-agent` / `ready-for-human` / `wontfix`.
- **Domain docs = single-context:** one `CONTEXT.md` at repo root + `docs/adr/`.
- **Phase 1→2 bridge:** `/build` reads `docs/issues/*.md` (or `docs/prd/PRD.md`) and writes
  `goals/<n>-<name>.{md,gates.sh,next-task.sh}` contracts. On the **first** conversion it
  **replaces the `goals/0-example.*` placeholder triplet** (a teaching example, not a real
  goal; see the Bootstrap rule in `goals/AGENTS.md`) rather than leaving it beside the real
  goals. Goal `<n>` is an ordering label, not a 1:1 map to issue `NNN`; link a goal to its
  issue by slug (`goals/<n>-<slug>`).
- **FCG invariants:** gates are immutable (fix code, not gates); `.state/` is gitignored;
  in loop mode never terminate early (stuck → climb the bounded escalation ladder, then log a
  blocker and move on — full ladder: `guidelines/goal-iteration.md` §When You Are Stuck).

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

> Sequence: `/grill` (account the decision surface into `docs/grill/checklist.md` until every slot
> closes) → `/freeze` (the one human approval point — seals the closed feature through
> to-prd → spec → to-issues → graph-lint as a sealed bundle) → `/build`. Freeze is **per-feature**
> (tracer-bullet): feature A can be sealing while feature C is still being grilled. Checklist
> convention: `docs/grill/README.md`.

- **Surface load-bearing choices before freezing the spec.** Persistence, delivery shape
  (service / library / CLI / UI), and stack are decisions the whole plan rests on — state them to
  the user **explicitly, with the trade-off**, never silently default. A silently-defaulted
  load-bearing choice traps a user who didn't know to object; they discover the wrong one only at
  build time. `/freeze` will not seal a contract while such a choice is unresolved.
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
  **asked-and-answered**, **deferred-tunable** (a default inside a settled mechanism, marked
  tunable), **experiment-pending** (a load-bearing choice a prototype will settle — parked, not
  guessed), or **N/A — covered** (a load-bearing lens deliberately excluded, with the covering
  argument named — e.g. "concurrency: N/A — single user"). These are the *semantic* exit states;
  their checklist **notation** (`[x]` / `[~]` / `[>]` / `[-]`) is owned by `docs/grill/README.md`
  (the single source for the symbols). Enumerate exhaustively, ask minimally — never ask what is
  derivable. Grilling ends when no **un-grounded** slot survives — not when it "feels like enough".
- **Filter candidate questions through a grounds-gate.** A question — or a new checklist item — may
  reach the user only when it can state three things: its **site** (which entity/slot), **why** the
  material at hand doesn't already settle it, and the **consequence** of guessing wrong. **The *why*
  is the termination engine:** actively argue that spec/code/harness/convention does *not* already
  cover it — "might be covered" is not enough; a loose *why* lets the surface grow without bound
  (infinite grilling moves into the file). A candidate that can't state all three is noise — drop it;
  don't spray "have you considered X?". The gate filters noise only — it is never a license to drop a
  load-bearing slot by under-arguing. When genuinely unsure whether a slot is load-bearing, ask: one
  question costs a beat, an un-surfaced decision costs a wrong build.
- **Demote incoming documents to material — track presence, not coverage.** A spec/plan/notes file
  brought from elsewhere enters as challengeable material, not ground truth: a document's existence
  is no evidence of the design conversation behind it. While accounting the surface, distinguish a
  slot the input merely *mentions* from one it *states with rules* — "touched" is not "covered",
  and only stated-with-rules counts toward `grounded`. Differences between sources (doc ↔ spoken ↔
  code) become questions, never silent picks.
- **Pre-freeze intent-audit (independent, two directions).** Right before `/freeze` seals the
  contract, dispatch one subagent that did **not** author the plan; it reads the dialogue + the
  decision surface and runs **both** audits: **(a) disposition** — is each `[x]`/`deferred` slot
  defensible from the dialogue, or was a guess rubber-stamped as grounded? (hunts over-claiming);
  **(b) residual-enumeration** — independently re-walk the four lenses over the entity manifest and
  colliding pairs to find any obligation-slot *nobody enumerated* (hunts under-listing). **Without
  (b) the closure condition is forgeable** — closure is defined on the checklist's own contents,
  which the agent controls, so simply omitting a checkbox would make a feature "closed". Each finding
  is closed by asking the user — never patched silently into a document; if closing one opens new
  edges, re-walk only the touched slots once, then escalate to the user (not an open loop). No
  subagent tooling (e.g. a Codex session) → run both as an explicit self-review pass and surface the
  list. This audit is **no license for shallow grilling** — a finding here means the dialogue was
  closed too early.
- **Freeze is one-way.** Once `/freeze` seals a feature, a *new* design idea about it goes to
  `docs/findings/` (not a checklist re-open); only a *fundamental error in a frozen decision* re-opens
  Phase 1, and only with explicit user approval. Routing: simple addition / conflict → findings; the
  frozen decision itself is wrong → `/grill` re-open.

## Gate validity (Phase 1→2) — trusting an LLM-written gate

Machine-checked gates give **reproducibility** (same code → same verdict), not **validity** (that the
condition is the *right* one). Three guards keep validity honest:

- **Authority comes from freeze, not invention.** A `.gates.sh` condition must be the mechanical
  translation of a `/freeze` acceptance criterion (`/build` mode B does issues→gates), not an LLM
  ad-lib. "Is this gate strange?" then reduces to "did it translate the criterion faithfully?" —
  checkable, because translation is verifiable where invention is not. The upstream guarantee is
  freeze's *verifiable floor* (criteria written so "was it met?" is decidable).
- **Red-first hygiene.** A newly written gate must be run against the **pre-implementation** code and
  **must fail (red)**. A gate that is green before any code exists checks nothing (`exit 0` /
  tautology) — red-first catches that class at once. (`/build` runs the new gate on current code at
  conversion and asserts red.)
- **green is necessary, not sufficient.** green = "the stated checks passed", not "everything is
  correct" — a permanent gap remains between a natural-language criterion and a bash check, and gate
  coverage is capped by decision-surface completeness (un-stated intent is outside the gate). The
  dashboard should show green as "this promise (the plain-language criterion) held"; RISKY independent
  review + occasional human spot-checks are the permanent complement. "There's a gate so I needn't
  look" is reward-hacking.

## Project-specific skills

`.claude/skills/` = skills only this project needs (global skills live in `~/.claude`, `~/.codex`).
Add one only when a pattern has proven to repeat — don't auto-generate agent/skill rosters
(context bloat hurts performance). Encode tailoring above and in `goals/<n>-*.gates.sh` instead.

## Doc & skill hygiene (when adding or editing a skill / doc)

The rules that make a multi-origin system read like one. Check new/edited files against them:

- **One canonical home per rule; cite, don't restate.** A rule lives in exactly one file; others link
  it ("see X") with at most a one-line gist — a second full copy is drift waiting to happen. (Model:
  `spec-sync` cites `§Spec authority` instead of pasting it.)
- **Density.** Every sentence must change what an agent does — if removing it breaks nothing, cut it.
  No decoration, no restating the obvious.
- **Stack-agnostic.** No concrete stack / framework / library / tool name in a skill or harness doc;
  the real stack is discovered at runtime. (Names inside `*EXAMPLE*` files are marked illustrative.)
- **Self-describing files.** A reference/doc opens with `# <filename> — <one-line role>`; a skill's
  `description:` ends with its trigger phrases.
- **Frozen terms.** Reuse the established term, don't coin synonyms (`graph-lint`, not a
  transliteration; the risk enum is exactly `RISKY | MECHANICAL | NONE`). Cite an AGENTS heading as
  `§Name` (e.g. `§Spec authority`, `§Phase 1`).
- **Overloaded terms — qualify when ambiguous.** "gate" = the machine `.gates.sh` goal check or the
  `graph-lint` hard gate (both machine-checked); the *pre-freeze intent review* is an **audit**, not
  a gate. "contract" = the `docs/spec/` interface (spec 계약) vs the goal triplet (goal 실행계약) vs
  issue frontmatter (machine-readable dependency contract) — qualify which when context doesn't disambiguate.
