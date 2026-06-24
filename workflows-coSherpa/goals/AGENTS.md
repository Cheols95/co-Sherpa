# `workflows-coSherpa/goals/` — Working Protocol for the mission stack

`workflows-coSherpa/goals/` is the **mission stack**: the versioned, machine-verified
definition of "what done means." The lowest-numbered goal whose gates fail
is the **active goal** — the single routing signal every harness tool
(`diagnose.sh`, `next-task.sh`, `active-check.sh`) reads.

Read `workflows-coSherpa/docs/goal-design.md` (design) and `workflows-coSherpa/guidelines/goal-iteration.md`
(per-iteration operating manual) before authoring or editing a goal.

---

## The three-file set

Each goal is **three files** sharing a `<n>-<name>` stem:

| File                      | Role                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| `<n>-<name>.md`           | Mission. States the "done" conditions in prose (use universal claims).                     |
| `<n>-<name>.gates.sh`     | Machine verification. **If the `.md` says "every X", the gate MUST enumerate X** from a source of truth. |
| `<n>-<name>.next-task.sh` | Advisory hint. Reads workflow state (file existence, gate pass/fail) and prints the next action. Never gates. |

`_meta` is a special set (no number) for cross-cutting invariants (lint /
typecheck / test / build); `completion-check.sh` launches it first.

**Discovery rule.** The harness treats a markdown file in `workflows-coSherpa/goals/` as a
goal only when its name starts with a digit (`<n>-<name>.md`) or is exactly
`_meta.md`. Anything else here — this `AGENTS.md`, `EXAMPLE.md`, a
`README.md`, scratch notes — is ignored by `completion-check.sh` /
`check-gate-rigor.sh` / `diagnose.sh`, so it never shows up as a "missing
gate" failure.

**Bootstrap rule — the first conversion replaces `0-example`.**
`workflows-coSherpa/goals/0-example.*` is a **teaching placeholder**, not part of the real
chain. The **first** `build` mode-B conversion (issues/PRD → goals)
MUST delete the `workflows-coSherpa/goals/0-example.{md,gates.sh,next-task.sh}` triplet as it
writes your first real numbered goal — otherwise the throwaway example
(name starts with `0`, so it is a live goal) lingers as a permanent
passing member of the chain. A fresh template keeps it so you can watch
the chain go green, and `workflows-coSherpa/scripts/reset-for-new-project.sh` preserves it
on copy; it is removed only at the first real conversion.

---

## `.md` conventions

- Put a one-line pointer right under the title so an agent that opens the
  goal first can reach the operating manual in one hop:

  ```
  > 이 goal을 active로 잡은 에이전트는 먼저 `workflows-coSherpa/guidelines/goal-iteration.md`를
  > 읽어 iteration 프로토콜을 확인할 것.
  ```

- Sections that work well: `## Mission`, `## Completion Conditions`,
  `## Sources Of Truth` (the enumeration commands), `## Verification`.
- Universal claims ("every / all / each <noun>") trigger the rigor check.
  Only claim universality when you mean it — and back it with an
  enumerating gate.

---

## Adding a goal

```
workflows-coSherpa/goals/<n>-<name>.md            # mission
workflows-coSherpa/goals/<n>-<name>.gates.sh      # machine verification (chmod +x)
workflows-coSherpa/goals/<n>-<name>.next-task.sh  # next-action hint (chmod +x)
```

Before authoring your first real goal — or converting issues in mode B —
read `workflows-coSherpa/goals/EXAMPLE.md` once: an annotated issue→three-file conversion
with the anti-patterns called out. It is documentation, not a goal (the
discovery rule ignores it), and it survives the `0-example` bootstrap
deletion.

The next `completion-check.sh` run picks the lowest failing goal as active.
Before writing it, run the **self-audit** in `workflows-coSherpa/docs/goal-design.md`
(§"새 goal 추가하기" → "작성 전 self-audit"): does this goal merely retarget a prior gate's path (case a),
require loosening a prior gate's logic (case b), or supersede a prior gate
(case c)? Prior gates are immutable unless one of those is explicitly
declared.

---

## Risk tier & RISKY close-out review

- A numbered goal's `.md` MAY open with frontmatter `risk: RISKY | MECHANICAL | NONE`,
  **carried from the source issue's frontmatter** at conversion (build mode B) or judged there by
  the **risk heuristic below**. An omitted `risk` is **unclassified, NOT mechanical**.
- **Risk heuristic (a floor, judged per slice) — single source.** `RISKY` if the slice names an
  explicit edge case, invariant, state-coordination or validation rule, **or** touches data integrity
  (schema/migration), auth/security boundaries, money, irreversible external effects, or the
  `workflows-coSherpa/docs/spec/` contract surface. `NONE` if it has no behavioral surface (workflows-coSherpa/docs/config/pure scaffold).
  `MECHANICAL` otherwise. `/to-issues` emit, `/build` mode B carry, and this close-out review all read
  this one definition (degrade-don't-corrupt: when unsure, bias toward RISKY).
- **Runtime upgrade-only.** If mid-loop the goal proves more behavioral / multi-file /
  ambiguous than declared (e.g. you feel the urge to touch a test or a prior invariant),
  upgrade to `RISKY` on the spot. Downgrading requires the user — never silent.
- **RISKY close-out review.** When a `RISKY` goal's gates go green, **before advancing**:
  dispatch one subagent that did **not** author the code. Give it the goal `.md` mission +
  the **raw diff** of this goal's labeled commits (`git log --oneline --grep='(<id>)'` —
  the `red/green/refactor/chore(<id>)` set) — never the implementer's summary (anchoring).
  Findings go to `workflows-coSherpa/docs/findings/` (finding 규약, file:line evidence) — they do **NOT**
  block the gate verdict: gates stay the only "done" authority; the review is semantic
  insurance for what gates can't see (proxy-gap, out-of-surface edits, weakened tests).
  No subagent tooling (e.g. a Codex solo loop) → queue the review request itself as a
  finding for the next session.

---

## Designing gates (summary — full rules in goal-design.md §1, §1.5)

- **Universal claim ⇒ enumerate from a source of truth** (filesystem,
  schema, route table). Never type the entity names into the gate.
- **Gates ≠ convention police.** Don't grep for what a test, typecheck, or
  coverage threshold catches more precisely. A gate legitimately owns only:
  the rigor mechanism, negative-universal greps ("X appears nowhere"), and
  structural anchors (a file's existence that routes a later goal).
- Skeptical heuristic: *"if this invariant broke, which test would go
  red?"* If one would, the test owns it — drop it from the gate.

Every gate should source `workflows-coSherpa/scripts/_gate-cache.sh`, declare `GATE_INPUTS`,
and end with a `check-gate-rigor.sh` self-check on its own `.md`.

---

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
  coverage is capped by decision-checklist completeness (un-stated intent is outside the gate). The
  dashboard should show green as "this promise (the plain-language criterion) held"; RISKY independent
  review + occasional human spot-checks are the permanent complement. "There's a gate so I needn't
  look" is reward-hacking.
