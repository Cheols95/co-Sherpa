---
title: "template-clean-check.sh misses spec/adr/findings/cycles leftovers"
created_at: 2026-06-21T09:00:00Z
resolved: false
priority: P2
related:
  - workflows-coSherpa/scripts/template-clean-check.sh
  - dev/release-verification/verify.sh
---

# template-clean-check.sh misses spec/adr/findings/cycles leftovers

## TL;DR

The harness template-cleanliness gate `workflows-coSherpa/scripts/template-clean-check.sh`
only flags PRD/issue/concept/goal/runtime leftovers. Project-specific
`docs/spec/`, `docs/adr/`, `docs/findings/`, and `cycles/` artifacts can leak
into a distributed template without being caught. spec/ADR are especially
risky because they carry project-specific decisions.

This was found while improving the dev/ release-verification package, where the
parallel audit `check_release_dist_clean` in `dev/release-verification/verify.sh`
was extended to cover these four categories. The harness-side script was left
out of scope (dev/ only) and is queued here.

## Body

`workflows-coSherpa/scripts/template-clean-check.sh` enumerates leftover
detection for prd/issues/concept/goals but not spec/adr/findings/cycles. The
dev package's own audit now covers them (allowlist: spec/adr keep only
`README/AGENTS/CLAUDE`; findings/cycles keep only `AGENTS/CLAUDE/EXAMPLE/README`),
so the two cleanliness checks have diverged. Bring the harness script to parity.

## Options / Recommendation

- (A) Mirror the four new loops + allowlists from `check_release_dist_clean`
  into `template-clean-check.sh`. **Recommended** — restores parity, single
  detection contract.
- (B) Have `template-clean-check.sh` delegate to a shared cleanliness library so
  both call sites stay in sync. Larger refactor; defer unless drift recurs.

## Acceptance signal

Add a dirty fixture (a stray `docs/spec/data-schema.md` and `docs/adr/0001-x.md`)
and assert `template-clean-check.sh` exits non-zero. Today it passes; it should
go red.
