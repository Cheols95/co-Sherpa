---
title: 문서 산문 중복을 canonical 인용으로 축소
created_at: 2026-06-14T16:00:45Z
resolved: false
priority: P2
related:
  - AGENTS.md
  - goals/AGENTS.md
  - skills/build/SKILL.md
  - skills/to-spec/SKILL.md
  - skills/freeze/SKILL.md
  - guidelines/goal-iteration.md
---

# 문서 산문 중복을 canonical 인용으로 축소

## TL;DR
몇몇 규칙의 *전체 산문*이 canonical 파일 외에도 복제돼 있다(인용은 있으나 1줄 gist가 아닌 절차 전문).
"한 곳 정본, 나머지는 인용"(`AGENTS.md` §Doc & skill hygiene) 규칙의 산문판 위반 — 드리프트 위험.
동작 영향 없어 P2.

## Body
- **intent-audit gate**: canonical `AGENTS.md:104-116`. 절차 전문이 `skills/to-spec/SKILL.md`(동결 전
  게이트 절)와 `skills/freeze/SKILL.md:28-37`에 재서술(freeze는 cite는 있으나 절차 전문도 함께 있음).
  freeze 경로에선 to-spec 0단계가 항상 생략되므로 to-spec 사본은 sealed 경로에서 dead weight.
- **risk close-out 절차**: canonical `goals/AGENTS.md:95-103`. `skills/build/SKILL.md:44-47`에 전문 중복.
- **escalation ladder**: canonical `guidelines/goal-iteration.md` §When You Are Stuck. `build:90`·
  `cycle:42`·`cycles/AGENTS.md`·`AGENTS.md:45` 에 gist+cite(각 cite 있어 경미 — 최저 우선).

## Options / Recommendation
각 복제처를 **1줄 gist + `§`인용**으로 축소, canonical은 유지. 우선순위: intent-audit > risk close-out >
ladder(ladder는 이미 cite 있어 선택적).

## Acceptance signal
각 규칙의 *전체 절차*가 정확히 1개 파일에만. 나머지 위치는 ≤1줄 요약 + `§` 인용.
`grep -rl 'residual-enumeration' .` 이 canonical + ≤1 gist만 남긴다.
