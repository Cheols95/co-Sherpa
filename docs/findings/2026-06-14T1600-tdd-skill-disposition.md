---
title: tdd 스킬 거취 — build/goal-iteration과 중복, 강등/제거 검토
created_at: 2026-06-14T16:00:45Z
resolved: false
priority: P2
related:
  - skills/tdd/SKILL.md
  - skills/build/SKILL.md
  - guidelines/goal-iteration.md
  - skills/to-issues/SKILL.md
---

# tdd 스킬 거취 — build/goal-iteration과 중복, 강등/제거 검토

## TL;DR
`build`(FCG 엔진)와 `goal-iteration`이 이미 RED→GREEN→REFACTOR를 강제 구동하므로, 독립 `/tdd` 스킬은
실질적으로 트리거되지 않는다(중복 설명). 핵심이 정확히 중복인지 점검 후, 스킬 트리거를 제거하고 가치 있는
보조문서만 `guidelines/`로 옮겨 build 참조용으로 남길지 결정. (2026-06-14 승철 질문에서 발견 — TDD
*방법론*은 build가 강제하므로 스킬을 빼도 살아있다.)

## Body
- **루프 중복**: `skills/build/SKILL.md:33`("TDD 루프")·`:42`("RED→GREEN"), `guidelines/goal-iteration.md`
  의 RED→commit→GREEN(전체 스위트)→commit→REFACTOR, goal `next-task.sh`의 RED/GREEN 힌트 vs
  `skills/tdd/SKILL.md:62-99`의 동일 루프.
- **vertical-slice/tracer-bullet 개념 이중 정의**: `skills/tdd/SKILL.md:29`와 `skills/to-issues/SKILL.md:24`
  에 각각 정의 — single owner 없음.
- **잔존 가치**: tdd 보조 문서(`tests.md`·`mocking.md`·`deep-modules.md`·`interface-design.md`·
  `refactoring.md`)는 "좋은 테스트/깊은 모듈을 *어떻게* 쓰나"의 상세 — build가 참조할 지식.

## Options / Recommendation
- (A) **Recommended** — `tdd` SKILL.md의 `description:` 트리거 제거 → `guidelines/tdd-method.md`로
  강등(보조 `.md` 동반), `build`/`goal-iteration`이 `§`로 인용. vertical-slice owner를 tdd(또는
  to-issues) 하나로 지정.
- (B) 유지 — 거의 트리거 안 되지만 context 비용은 낮음.

## Acceptance signal
`build`/`goal-iteration`이 TDD 루프의 유일 소유자(tdd는 "좋은 테스트 작성법"만 소유). `tracer bullet`
정의가 정확히 한 곳. `/tdd` description 트리거가 build와 겹치지 않는다(또는 제거됨).
