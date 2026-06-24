# workflows-coSherpa/docs/concept/ — Phase 1 concept state and non-contract design docs

Phase 1 `/concept`의 **결정 체크리스트(decision checklist)** 상태 파일과, 계약은 아니지만 구현에 필요한 설계 산출물을 둔다.

`/concept`은 `checklist.md`를 생성·갱신하고, `/freeze`가 이를 읽어 동결한다. `checklist.md`는 프로젝트 생성물이다.
배포 manifest에는 이 `README.md`(규약)만 들어가고 `checklist.md`는 넣지 않는다. `reset-for-new-project.sh`도
`checklist.md`를 지우지 않는다.

## Phase 1 체크리스트

"언제 concept가 끝나는가"를 느낌이 아니라 **측정 가능한 상태(잔여 체크박스 수)**로 만든다. 열린 질문은
무한히 생성 가능하므로, 종료는 "더 물을 게 없다"가 아니라 **"4관점 격자의 모든 칸이 닫혔다"**로 정의한다.

## 항목 입장 규칙

1. **열거는 4관점 스캔으로** 한다. 엔티티 매니페스트를 먼저 적고, 각 엔티티와 충돌쌍에 네 관점을 적용한다.
   - **STRUCTURAL** 카디널리티·정체성·구성
   - **BEHAVIORAL** 수명주기·동시성·규칙 및 정책·엣지
   - **TECHNICAL** 데이터 저장·인터페이스·일관성
   - **CONTRACT** 상태·enum *집합*·유일성·출력키
2. **입장은 grounds-gate 3요소를 통과해야만** 한다: site, 기존 자료로 정산 안 되는 이유, 틀리게 추측할 때의 결과.
   못 대면 소음이므로 폐기한다.

## 닫힘 상태 4종

| 표기 | 의미 | 닫힘 조건 |
|---|---|---|
| `[x]` | 결정 | 닫힘 근거와 동시 체크. hard-to-reverse면 ADR 번호, 가벼우면 rationale 한 줄 |
| `[~]` | 보류 | 기본값 명시 + "변경 비용 낮음" 근거 한 줄 |
| `[>]` | 실험 정산 대기 | 어느 프로토타입이 정산하는지 명명. 결과 나오면 근거 적으며 `[x]`로 전환 |
| `[-]` | 관점 N/A | 그 관점이 load-bearing이나 배제됨 + 배제 근거 한 줄 |

미표기 `[ ]` 0개 **그리고** 미정산 `[>]` 0개 → `/concept`이 **"기능 X 닫힘 — /freeze ready"** 선언.

## 파일 형식 예시 (`workflows-coSherpa/docs/concept/checklist.md`)

```markdown
# concept Checklist
<!-- 항목 입장: grounds-gate 3요소. 동결 기능의 신규 기획거리는 findings로,
     동결 결정의 근본 오류는 concept 재오픈으로. -->

## 기능1: A — FROZEN (2026-06-14, /freeze 완료 → issues 001~003)
- [x] 저장 방식 (STRUCTURAL) — ADR-003
- [x] 동시 편집 정책 (BEHAVIORAL) — ADR-004
- [x] 입력 검증 위치 (CONTRACT) — rationale: 컨트롤러 단일 진입, 변경 시 ADR 승격
- [~] 캐시 TTL (TECHNICAL) — 보류: 기본 60s, 런타임 설정이라 변경 비용 낮음
- [-] 동시성 (BEHAVIORAL) — N/A: 단일 사용자, 경쟁 쓰기 없음

## 기능2: B — 진행 중 (2/4 닫힘)
- [x] 입력 포맷 (CONTRACT) — ADR-006
- [>] 렌더링 한계치 (TECHNICAL) — 실험 정산: prototype/engine-stress
- [ ] 실패 시 재시도 정책 (BEHAVIORAL)
```

## 비계약 설계 문서

계약은 아니지만 구현에 필요한 설계 산출물도 여기에 둔다. `workflows-coSherpa/docs/spec/`와 달리 **권위가 없다**. 구현은 참고하되
충돌 시 `workflows-coSherpa/docs/spec/`가 이긴다.

| 문서 | 담는 것 |
|---|---|
| `flow.md` | 사용 흐름·유스케이스·상태머신·시퀀스 |
| `screens.md` | 화면/UI 설계, 와이어프레임 |
| `architecture.md` | 코드 모듈 경계·의존 방향. 결정 자체는 `workflows-coSherpa/docs/adr/` |

- `/to-spec`이 계약을 추출할 때 비계약 내용을 여기로 분류한다. 직접 작성도 가능하다.
- 아키텍처 발굴은 `/improve-codebase-architecture`가 맡는다.
- 안정 인터페이스(스키마·API·공개 타입)는 여기가 아니라 `workflows-coSherpa/docs/spec/`에 둔다.
