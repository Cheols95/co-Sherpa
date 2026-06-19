# Goal 0 — (example) runnable scripts carry a shebang

> 이 goal을 active로 잡은 에이전트는 먼저 `workflows-coSherpa/guidelines/goal-iteration.md`를
> 읽어 iteration 프로토콜을 확인할 것.

> **This is a throwaway teaching example.** It demonstrates the three-file
> goal shape and the universal-claim ↔ enumeration rule, and it passes out
> of the box so you can watch the chain turn green. Once you understand the
> pattern, the normal path is to run **build** on your issues/PRD: its
> conversion (mode B) writes `workflows-coSherpa/goals/<n>-<name>.{md,gates.sh,next-task.sh}`
> from your spec and **removes this triplet** as it does so (the
> `workflows-coSherpa/goals/AGENTS.md` bootstrap rule; you can also delete it by hand).

## Mission

Every shell script under `workflows-coSherpa/scripts/` that is meant to be run directly
(i.e. not a sourced helper prefixed with `_`) begins with a `#!` shebang.

## Completion Conditions

1. Every runnable `workflows-coSherpa/scripts/*.sh` starts with a `#!` line.
2. This goal's gate passes `workflows-coSherpa/scripts/check-gate-rigor.sh`: the universal
   claim above forces the gate to **enumerate** the filesystem rather than
   sample a single file.

## Sources Of Truth

- `find scripts -maxdepth 1 -name '*.sh' ! -name '_*'`

## Verification

```
bash workflows-coSherpa/goals/0-example.gates.sh
bash workflows-coSherpa/scripts/completion-check.sh
```
