# `workflows/cycles/` — Working Protocol for cycle-driver documents

## What this directory is

`workflows/cycles/` holds **loop-driver prompts** — the documents you hand to an
autonomous coding agent in infinite-loop mode:

```
<your /goal-style command> workflows/cycles/260526-01-overnight-findings-sweep.md
의 내용을 모두 완수할 때까지 작업해줘.
```

A cycle document describes **one work session**: it picks unresolved items
from `workflows/docs/findings/`, orders them by priority/dependency, and drives a TDD
loop that closes them — promoting some into `workflows/goals/<n>-*` harness goals,
doing the rest directly. It is a _prompt_, not a contract.

---

## cycle ≠ harness goal

|              | `workflows/goals/<n>-*.md`                                          | `workflows/cycles/YYMMDD-NN-*.md`                |
| ------------ | -------------------------------------------------------- | -------------------------------------- |
| Discovered by| `completion-check.sh` via `find goals -maxdepth 1`       | a human, by handing the path to a loop |
| Nature       | a persistent **invariant** verified by a gate            | a **prompt** for one session (history) |
| Verification | `.gates.sh` + `check-gate-rigor.sh`                      | none — the body states its exit test   |

The harness only scans the top of `workflows/goals/`, so this folder is **never a
gate target**. Keep cycle documents after completion — they are history.
Do not delete them.

---

## Filename convention

```
workflows/cycles/<YYMMDD>-<NN>-<slug>.md
```

- `<YYMMDD>` — cycle start date (e.g. `260526` = 2026-05-26).
- `<NN>` — sequence within that date (`01`, `02`, …). You may start
  several cycles a day, so the order must be explicit.
- `<slug>` — short, lowercase, hyphenated. The date is already in the
  prefix; don't repeat it in the slug.

Examples:

```
workflows/cycles/260523-01-overnight-findings-closure.md
workflows/cycles/260524-01-post-review-findings-closure.md
workflows/cycles/260526-01-overnight-findings-sweep.md
```

---

## Frontmatter (required)

Every cycle document starts with YAML frontmatter recording its lifecycle
in a machine-readable way.

| Field          | Meaning            | Notes                                              |
| -------------- | ------------------ | -------------------------------------------------- |
| `cycle`        | `YYMMDD-NN` id     | matches the filename prefix                        |
| `title`        | short title        | same as the `# H1`                                 |
| `authored_at`  | **authored time**  | when the doc was written (ISO-8601 w/ offset)      |
| `started_at`   | **start time**     | when it was handed to the loop. Blank if unstarted |
| `completed_at` | **completion time**| loop termination time. Blank if incomplete         |
| `status`       | **state**          | `draft`→`running`→`complete`\|`partial`\|`aborted` |

```yaml
---
cycle: 260526-01
title: Overnight findings sweep
authored_at: 2026-05-26T01:03:39+09:00
started_at:
completed_at:
status: draft
---
```

- **status transitions**: `draft` (written, not started) → `running` (set
  `started_at`) → on exit one of `complete` (all in-scope closed) /
  `partial` (some deferred) / `aborted`, plus `completed_at`.
- **For historical docs, derive timestamps from git**: `authored_at` =
  `git log --follow --diff-filter=A --format='%aI' -- <path>` (first add);
  `completed_at` = the cycle's last closure commit author date.

---

## A cycle document MUST contain

Generator meta-prompt: `workflows/prompts/cycle-generate.md`. Minimum structure:

1. **Goal + target findings** — the findings to close and their
   ordering / dependencies.
2. **Loop algorithm** — check chain state → finish any unfinished goal →
   next finding.
3. **Finding-processing procedure** — read / decide promote·delegate·
   direct / execute (TDD) / verify / wrap up (frontmatter + Resolution).
4. **Out of scope** — items deliberately untouched (don't fix even if
   spotted; say why).
5. **Forbidden actions** — HARD STOP rules.
6. **Commit / push protocol**.
7. **Termination / verification** — the commands that confirm it's
   actually done. The termination report MUST also carry the cycle-end
   doc-sync advisory: recommend one `/spec-sync` pass (contract ↔ code
   drift) as the next action — the chain just changed the most, so this
   is the cheapest moment to reconcile `workflows/docs/spec/`.

---

## Authoring rules

Read before authoring: `workflows/docs/goal-design.md` (especially §1.5, §5),
`workflows/guidelines/goal-iteration.md`, your commit convention, and
`workflows/docs/findings/AGENTS.md`.

- **Don't force snapshots/logs closed.** `kind: snapshot` /
  `append-only-log` findings (audit, dogfood, perf records) are not
  "resolve" targets. Close the **child work items** they decompose into;
  leave the snapshot as a reference.
- **Promote sparingly.** Only promote a finding to a goal when all three
  hold: (a) it's a gate-verifiable universal invariant, (b) it's
  multi-step RED/GREEN, (c) it's semantically distinct from prior goals.
  Minimal-gate rules: `workflows/docs/goal-design.md §1.5`.
- **Design for unattended (overnight) runs.** Put deep, safe queues
  (large per-file work) last; mark items needing design decisions
  out-of-scope. When stuck, climb the bounded escalation ladder
  (context-reinforced retry → approach-switch retry → write a blocker →
  next target) and **never terminate early** — terminate only when every
  in-scope target is resolved/partial and the chain is green. Ladder
  steps and counts: `workflows/guidelines/goal-iteration.md` §When You Are Stuck.
- **Output discipline (loop mode).** Speak only at a real question, a
  target/cycle result, or a blocker — no transition narration (tool calls
  are already visible). Full rule: `workflows/skills/build/SKILL.md` §출력 규율.

---

## Lifecycle

1. **Generate** — author a new cycle doc with `workflows/prompts/cycle-generate.md`.
2. **Run** — hand `workflows/cycles/<file>` to the infinite-loop agent.
3. **History** — keep the file after completion (don't delete). The next
   cycle inherits the previous one's out-of-scope / deferred items.

When referencing another file, use repo-rooted paths
(`workflows/docs/findings/<file>.md`, `workflows/goals/<n>-<name>.md`, `workflows/cycles/<file>.md`) —
no `./` or `../`.
