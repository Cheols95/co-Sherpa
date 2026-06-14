---
title: 소규모 정합 — finding kind 노출 · cycle-generate↔cycle · DEEPENING orphan
created_at: 2026-06-14T16:00:45Z
resolved: partial
priority: P2
status_notes: |
  (a) finding kind 노출 — CLOSED 2026-06-15 (skills/finding/SKILL.md frontmatter에 kind 필드 추가).
  (c) DEEPENING orphan — CLOSED 2026-06-15 (improve-codebase-architecture/SKILL.md Grilling 루프에서 링크).
  (b) cycle-generate↔cycle — 부분: 역할 분담 노트만 추가(스킬=트리거, generate=raw 붙여넣기용,
      둘 다 cycles/AGENTS.md 위임). 절차 전문 통합/축소는 보류 — 둘 다 이미 AGENTS 위임이라 중복 경미.
related:
  - skills/finding/SKILL.md
  - skills/cycle/SKILL.md
  - prompts/cycle-generate.md
  - skills/improve-codebase-architecture/DEEPENING.md
---

# 소규모 정합 — finding kind 노출 · cycle-generate↔cycle · DEEPENING orphan

## TL;DR
세 개의 저위험 정합 항목 묶음. 각각 독립적으로 닫을 수 있다.

## Body
1. **finding `kind` 미노출**: `docs/findings/AGENTS.md:49`가 `kind: snapshot | append-only-log`를
   정의하고 cycle이 참조(`skills/cycle/SKILL.md:41`, `cycles/AGENTS.md:118`)하나, finding을 *생성*하는
   진입 스킬 `skills/finding/SKILL.md`엔 `kind:` 필드 언급이 없다 → 사용자가 snapshot finding을 표시할
   방법이 스킬에서 안 보임. **수정**: finding 스킬에 `kind:` 1줄(+ `docs/findings/AGENTS.md` 인용) 추가.
2. **cycle-generate ↔ cycle 절차 중복**: `prompts/cycle-generate.md`와 `skills/cycle/SKILL.md`가 cycle
   작성 절차를 모두 전문 서술(둘 다 `cycles/AGENTS.md`로 위임하나 절차가 겹침). **수정**: cycle-generate를
   순수 paste-in 텍스트로 축소하거나 삭제(참조 `cycles/AGENTS.md:92,141`·`cycles/EXAMPLE.md:14` 갱신 필요).
3. **DEEPENING.md orphan**: `skills/improve-codebase-architecture/DEEPENING.md`를 어떤 SKILL.md도
   링크하지 않음(SKILL은 `LANGUAGE.md`만 참조). **수정**: SKILL에서 링크하거나 제거.

## Acceptance signal
1. `skills/finding/SKILL.md`에 `kind:` 언급 존재.
2. cycle 작성 절차가 1개 소유(나머지는 인용).
3. `DEEPENING.md`가 SKILL에서 참조되거나 제거됨.
