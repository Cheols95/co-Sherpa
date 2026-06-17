# AGENTS.md — Project context & rules

Entry point for Codex/GPT (Claude reads this via `CLAUDE.md`'s `@AGENTS.md` import). This repo runs on
the **FCG** harness. **Claude and GPT are interchangeable peers — either model runs the full flow
(concept → freeze → build); no role split.**

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
  `depends: [NNN, ...]` (inline list of blocking issue ids — mirrors the prose "Blocked by"; on
  disagreement frontmatter wins) and `risk: RISKY | MECHANICAL | NONE` (**judgment heuristic:
  `goals/AGENTS.md` §Risk tier**; omitted = unclassified, NOT mechanical). `/to-issues` emits both; the
  roadmap dashboard reads `depends:`; `/build` mode B carries `risk:` into the goal contract.
- **Triage roles:** `needs-triage` / `needs-info` / `ready-for-agent` / `ready-for-human` / `wontfix`.
- **Domain docs = single-context:** one `CONTEXT.md` at repo root + `docs/adr/`.
- **Phase 1→2 bridge:** `/build` reads `docs/issues/*.md` (or `docs/prd/PRD.md`) and writes
  `goals/<n>-<name>.{md,gates.sh,next-task.sh}` contracts. On the **first** conversion it **replaces
  the `goals/0-example.*` placeholder triplet** (a teaching example, not a real goal; see the Bootstrap
  rule in `goals/AGENTS.md`). Goal `<n>` is an ordering label, not a 1:1 map to issue `NNN`; link a
  goal to its issue by slug (`goals/<n>-<slug>`).
- **FCG invariants:** gates are immutable (fix code, not gates); `.state/` is gitignored; in loop mode
  never terminate early (stuck → climb the bounded escalation ladder, then log a blocker and move on —
  full ladder: `guidelines/goal-iteration.md` §When You Are Stuck).

## Spec authority (which doc wins on conflict)

- **Current contract = only what `docs/spec/INDEX.md` lists** (schema, API contract, public types in
  `docs/spec/`). This is the single source of truth for implementation. On any conflict, it overrides
  PRD and ADRs.
- **Read order for implementation:** `AGENTS.md` → `CONTEXT.md` (glossary) → `docs/spec/INDEX.md` →
  the contract docs it points to → latest accepted ADRs → code & tests.
- **PRD (`docs/prd/`) = original intent, not current state.** Don't treat it as the live spec.
- **ADR (`docs/adr/`) = decision history, one decision per file.** A `superseded by ADR-NNNN` ADR is
  history, not a basis for implementation. ADRs stay in place — don't archive to read out of context.

## Phase 1 elicitation (planning gate) — full rules in `docs/design/AGENTS.md`

Sequence: `/concept` (account the decision surface in `docs/design/checklist.md` until every slot closes)
→ `/freeze` (the one human approval point — seals the closed feature through to-prd → spec → to-issues
→ graph-lint) → `/build`. **The full Phase-1 rules (four-lens decision surface, grounds-gate, pre-freeze
intent-audit, freeze-is-one-way) are the single source in `docs/design/AGENTS.md`** — `/concept` and
`/freeze` read it before working. Checklist format: `docs/design/README.md`.

## Gate validity (Phase 1→2) — full rules in `goals/AGENTS.md` §Gate validity

green is **necessary, not sufficient**: green = "the stated checks passed", not "correct". A gate's
authority comes from translating a `/freeze` criterion (not LLM invention), every new gate must be
red-first, and "there's a gate so I needn't look" is reward-hacking. **Full guards live in
`goals/AGENTS.md` §Gate validity** — `/build` reads it when writing gates.

## Project-specific skills

`.claude/skills/` and `.agents/skills/` = platform-local skills only this project needs
(global skills live in `~/.claude`, `~/.codex`). Keep Claude/Codex copies in parity unless a
platform constraint requires a split. Add one only when a pattern has proven to repeat — don't
auto-generate agent/skill rosters (context bloat hurts performance). Encode tailoring above and in
`goals/<n>-*.gates.sh` instead.

## Doc & skill hygiene (when adding or editing a skill / doc)

The rules that make a multi-origin system read like one:

- **One canonical home per rule; cite, don't restate.** A rule lives in exactly one file; others link
  it ("see X") with at most a one-line gist — a second full copy is drift waiting to happen.
- **Density.** Every sentence must change what an agent does — if removing it breaks nothing, cut it.
- **Stack-agnostic.** No concrete stack / framework / library / tool name in a skill or harness doc;
  the real stack is discovered at runtime. (Names inside `*EXAMPLE*` files are marked illustrative.)
- **Self-describing files.** A reference/doc opens with `# <filename> — <one-line role>`; a skill's
  `description:` ends with its trigger phrases.
- **Frozen terms.** Reuse the established term, don't coin synonyms (`graph-lint`, not a
  transliteration; the risk enum is exactly `RISKY | MECHANICAL | NONE`). Cite a heading as `§Name`.
- **Overloaded terms — qualify when ambiguous.** "gate" = the machine `.gates.sh` goal check or the
  `graph-lint` hard gate (both machine-checked); the *pre-freeze intent review* is an **audit**, not a
  gate. "contract" = the `docs/spec/` interface vs the goal triplet vs issue frontmatter.
