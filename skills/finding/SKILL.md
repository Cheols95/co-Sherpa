---
name: finding
description: "FCG 부채/통찰 큐. 현재 goal 범위 밖에서 발견된 기술부채·버그·추가요구·리뷰 통찰을 잃지 않도록 docs/findings/에 문서로 기록·갱신·정리한다. 'finding 기록해줘', 'finding', '나중에 할 일 적어둬', '부채 큐 정리', '이건 범위 밖이니 적어두자' 요청 시 활성화. 리뷰 대화에서 나온 통찰도 finding의 1급 출처다."
---

# finding — 부채/통찰 큐

`docs/findings/`는 **out-of-scope 발견을 잃지 않는 큐**다. goal iteration 중 곁가지로 발견한 부채, 또는 리뷰 대화에서 나온 통찰을 여기에 적는다. finding은 goal이 아니다 — gate 없음, `completion-check.sh`를 막지 않음, 누구나 자유롭게 편집 가능.

> 전체 규약은 프로젝트 `docs/findings/AGENTS.md` 참조. 이 스킬은 그 진입점이다.

## 언제 만드나
- (a) goal 진행 중 인접 부채를 발견했을 때, (b) 사람↔에이전트 리뷰 대화에서 통찰·부채가 나왔을 때. (회귀·계약 위반은 goal gate가 이미 기계검증하므로, 리뷰의 목적은 검증이 아니라 소통·상호학습 → 거기서 나온 통찰을 finding으로 큐잉해야 루프가 닫힌다.)

## 파일 규약
```
docs/findings/<YYYY-MM-DDTHHMM>-<slug>.md      # UTC, 콜론/초 없음. slug은 소문자-하이픈
```

## Frontmatter (필수)
```yaml
---
title: <짧은 명사구>
created_at: 2026-MM-DDTHH:MM:SSZ      # 파일명 prefix와 분 단위까지 일치
resolved: false                        # false | partial | true
priority: P2                           # P0 데이터무결성/체인블로커 | P1 릴리즈전 위험 | P2 릴리즈후 정리 (선택)
related:                               # 선택: 다른 finding/goal/소스 경로
  - docs/<other>.md
---
# <title 과 동일>
```
부분 종결 시 `resolved: partial` + `status_notes`로 남은 항목 명시. 종결 commit이 있으면 `resolved_by: <sha>`.

## 본문 (60초 안에 스캔 가능하게, ~400줄 넘으면 분할)
1. `# H1` 제목 (frontmatter title과 동일)
2. **TL;DR** (1~3문장): 무엇이 깨졌나/큐잉됐나, 왜 아직 안 고쳤나
3. **본문**: 모든 주장에 **file:line** 근거. file:line을 못 짚으면 finding이 아니라 hunch다.
4. (선택) Options/Recommendation · Acceptance signal(닫혔음을 확인할 구체적 테스트/grep) · Migration plan

## 출력 규율
큐잉은 조용한 작업이다 — 기록 완료(경로+한 줄 요약)만 보고하고 과정은 내레이션하지 않는다. (일반 규율: `skills/build/SKILL.md` §출력 규율 — 질문/결과/blocker만 말함.)

## 정직성 규칙
- 종결 주장 전 **코드로 검증**: 문서가 "Goal X가 A를 닫는다"고 해도 그건 *계획*이지 사실이 아니다. 해당 file:line을 grep/Read로 확인 후 `resolved: true`.
- 닫을 때 **증거 인용**(`file:line` 또는 테스트명)을 붙인다.
- bullet을 지우면 그 삭제는 닫은 commit/gate를 명시한 커밋 메시지로 뒷받침.

## 수명
create → update(`status_notes` 추가) → promote(goal로 승격 시 finding 삭제 금지, "promoted to goal N" 표기) → resolve(`resolved: true`, 파일은 이력으로 보존) → archive(append-only-log가 ~100엔트리/6개월 초과 시 `docs/archive/findings/`로).
