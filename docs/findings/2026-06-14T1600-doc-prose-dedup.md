---
title: 문서 산문 중복을 canonical 인용으로 축소
created_at: 2026-06-14T16:00:45Z
resolved: true
priority: P2
resolved_by: b1c4585
related:
  - docs/grill/AGENTS.md
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

## Resolution

**resolved 2026-06-15 (commit `b1c4585`).** 정본 위치는 v1.6 축약으로 이동했고
(intent-audit: 루트 `AGENTS.md` → `docs/grill/AGENTS.md` §Pre-freeze intent-audit;
risk close-out: `goals/AGENTS.md` §Risk tier & RISKY close-out review), 복제처를
**action-gist + § 인용**으로 축소했다. 정본은 폴더 진입 시 @import 자동로드됨이
검증돼(메모리 `template-subdir-import-loadcheck`) 안전하고, Codex 대비 "필독" 병기.

- **intent-audit**: `skills/freeze/SKILL.md` ① + `skills/to-spec/SKILL.md`
  §동결 전 게이트 — (a)/(b) 정의·4렌즈 세부·forgeable 근거·재walk 전문을 정본으로
  넘기고 실행 요지+cite만 남김. freeze의 "to-spec 0단계 생략" 노트와 to-spec의
  standalone 적용성(sealed일 때만 생략 명시)은 **보존**.
- **risk close-out**: `skills/build/SKILL.md` Rigor 4 — 전문 → `goals/AGENTS.md`
  §Risk tier & RISKY close-out review (cite를 정확한 전체 헤딩으로 교정).
- **ladder (C)**: 이미 gist+cite라 미변경(원 finding 지시).

**검증**: 비저자 서브에이전트 1회가 before/after diff에서 누락 action-instruction
**0** 확인(SAFE — 정본으로 옮긴 near-verbatim 절은 전부 recoverable). 3개 cite 모두
정본 헤딩으로 resolve(grill §Account L24·§Pre-freeze L52, goals §Risk tier L86).

**Acceptance 재해석**: `grep -rl 'residual-enumeration'`은 canonical + freeze gist
외에 `skills/grill/SKILL.md:37`·`docs/grill/README.md:40`·`Workflow_Guideline_v1.html`·
이 finding 파일도 잡지만, 전부 **≤1줄 mention + cite**(format-doc 교차참조·사용자
가이드)이지 *전문 복제*가 아니다 — 원 acceptance "canonical + ≤1 gist"의 *정신*
(full-prose duplicate 0)은 충족. 전체 절차는 이제 정본 1곳에만 존재.
