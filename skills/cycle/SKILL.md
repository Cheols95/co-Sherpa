---
name: cycle
description: "FCG 사이클 드라이버 작성기. docs/findings/의 미해결 finding들을 우선순위·의존성으로 묶어 cycles/<YYMMDD>-<NN>-<slug>.md 한 세션 loop-driver 프롬프트로 정리한다. 'cycle 만들어줘', 'cycle', '쌓인 findings 묶어줘', '야간 작업서 만들어줘' 요청 시 활성화. 생성한 cycle 문서는 /build cycles/<파일>.md 로 실행한다."
---

# cycle — 사이클 드라이버 작성기

`cycles/`는 **loop-driver 프롬프트** 모음이다 — 무한 루프 모드의 코딩 에이전트에게 통째로 넘기는 한 세션 작업서. 이 스킬은 `docs/findings/`의 미해결 항목을 골라 **하나의 cycle 문서**로 묶는다. cycle은 goal이 아니다(gate 없음, `completion-check.sh`가 스캔 안 함) — 실행은 `/build cycles/<파일>.md`로 한다.

> 전체 규약은 프로젝트 `cycles/AGENTS.md`, 생성 메타 프롬프트는 `prompts/cycle-generate.md` 참조.

## 작성 절차
1. **대상 listup**: `docs/findings/`에서 `resolved: false`/`partial` 문서를 나열한다.
2. **실제 현황 확인**: 각 finding을 코드와 대조해 정말 미해결인지 검증(문서 ≠ 사실). 병렬로 빠르게.
3. **순서화**: 우선순위(P0>P1>P2)·의존성으로 정렬. 무인 운영이면 깊고 안전한 큐(대형 per-file 작업)는 뒤로, 설계 판단이 필요한 항목은 out-of-scope로.
4. **품질 게이트 삽입**(선택): "finding 2개 처리마다 `guidelines/품질점검.md`에 따라 메타시스템·lint·테스트코드를 점검하고 개선 goal을 생성" 같은 주기 점검을 본문에 명시.
5. cycle 문서를 작성한다(아래 구조).

## 파일 규약
```
cycles/<YYMMDD>-<NN>-<slug>.md     # YYMMDD 시작일, NN 그날 순번, slug 소문자-하이픈
```

## Frontmatter (필수)
```yaml
---
cycle: 260603-01
title: <짧은 제목>
authored_at: 2026-06-03T01:03:39+09:00
started_at:                 # 루프에 넘길 때 채움
completed_at:               # 종료 시 채움
status: draft               # draft → running → complete|partial|aborted
---
```

## 본문 필수 구성
본문이 담을 섹션과 상세 규격은 `cycles/AGENTS.md` §"A cycle document MUST contain"(단일 출처)을 따른다 — 요지: Goal+대상 findings · 루프 알고리즘 · finding 처리 절차 · Out of scope · Forbidden actions · Commit/push 프로토콜 · Termination/verification(완료 확인 명령 + 종료 보고에 `/spec-sync` 1회 권고 — 근거는 그 절의 Termination/verification 항). 출력 규율은 `skills/build/SKILL.md` §출력 규율.

## 작성 규율
- **promote는 아껴서**: finding→goal 승격은 (a) gate 검증 가능한 universal invariant, (b) 다단계 RED/GREEN, (c) 기존 goal과 의미상 구분될 때만.
- **snapshot/append-only-log finding은 강제 종결 금지** — 그것이 분해한 child 작업만 닫고, 스냅샷은 레퍼런스로 남긴다.
- **무인(야간) 운영 설계**: 무진전이면 사다리(맥락 보강 → 접근 전환 → blocker 기록 후 다음 target)를 밟되 **절대 조기 종료 금지** — 모든 in-scope가 resolved/partial이고 체인이 green일 때만 종료. 사다리 단계·횟수: `guidelines/goal-iteration.md` §When You Are Stuck.

## 수명
generate(이 스킬) → run(`/build cycles/<파일>`) → history(완료 후에도 삭제 금지, 다음 cycle이 이전의 out-of-scope/deferred를 승계).
