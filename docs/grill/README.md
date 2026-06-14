# docs/grill/ — Grilling 체크리스트 규약

Phase 1 grilling의 **결정표면(decision surface)** 상태 파일이 사는 곳.
`/grill`이 `checklist.md`를 생성·갱신하고, `/freeze`가 이를 읽어 동결한다.

- **`checklist.md` = 프로젝트 생성물**(템플릿 자산 아님). 새 프로젝트에서 `/grill`이 만든다.
  배포 manifest엔 이 `README.md`(규약)만 들어가고 `checklist.md`는 안 들어간다.
  `reset-for-new-project.sh`는 `checklist.md`를 지우지 않는다.

## 무엇을 푸는가

"언제 grilling이 끝나는가"를 느낌이 아니라 **측정 가능한 상태(잔여 체크박스 수)**로 만든다.
열린 질문은 무한히 생성 가능하므로, 종료는 "더 물을 게 없다"가 아니라
**"4렌즈 격자의 모든 칸이 닫혔다"**로 정의한다.

## 항목 입장 규칙 (없으면 무한 grilling이 파일 안으로 이사올 뿐)

1. **열거는 4렌즈 스캔으로** (자유연상 금지). 엔티티 매니페스트를 먼저 적고, 각 엔티티와
   충돌쌍에 네 렌즈를 적용한다 —
   - **STRUCTURAL** 카디널리티·정체성·구성 (one X = one/many Y?)
   - **BEHAVIORAL** 수명주기·동시성·정책·엣지
   - **TECHNICAL** 저장·인터페이스·일관성
   - **CONTRACT** 상태·enum *집합*·유일성·출력키
2. **입장은 grounds-gate 3요소를 통과해야만**: ① 어느 지점의 결정인지(site)
   ② **왜 기존 자료(spec·code·harness·관례)로 정산 안 되는지 — 능동적 배제**(ground②)
   ③ 틀리게 추측하면 무슨 일이 나는지(consequence). 못 대면 소음 → 폐기.
   - ⚠ **ground②가 종료의 실제 엔진**이다. "있을 수도"는 부족 — 이미 처리됨을 *적극* 논증해야
     표면이 유한해진다. ground②가 느슨하면 표면이 무한히 커진다(= 무한 grilling이 파일로 이사).

## 닫힘 상태 4종

| 표기 | 의미 | 닫힘 조건 |
|---|---|---|
| `[x]` | 결정 | 닫힘 근거와 동시 체크. hard-to-reverse면 ADR 번호, 가벼우면 rationale 한 줄(ADR 강제 안 함) |
| `[~]` | 보류 | 기본값 명시 + "변경 비용 낮음" 근거 한 줄 |
| `[>]` | 실험 정산 대기 | 어느 프로토타입이 정산하는지 명명. 결과 나오면 근거 적으며 `[x]`로 전환 |
| `[-]` | 렌즈 N/A | 그 (엔티티×렌즈)가 load-bearing이나 배제됨 + 배제 근거 한 줄 (예: "동시성: N/A — 단일 사용자") |

- **전수(全數) 형식**: 모든 (엔티티 × 렌즈)가 위 4종 중 하나여야 한다. *빈칸을 안 쓰는 것이
  "닫힘"이 되지 않도록* — 이 격자가 `/freeze`의 residual-enumeration 감사가 대조하는 기준이다.
- **`[>]`가 프로토타입 무한루프의 해법**: 실험마다 "어느 항목을 닫으려는가" 이름표가 붙어
  "만족할 때까지"(무한)가 "이 항목이 닫힐 때까지"(유한)로 바뀐다. 정산 대상 없는 실험은 시작 안 함.

## 기능 닫힘 판정

미표기 `[ ]` 0개 **그리고** 미정산 `[>]` 0개 → `/grill`이 **"기능 X 닫힘 — /freeze 가능"** 선언.

## 동결 후 (일방향)

- 동결된 기능에 **새 기획거리** → 체크리스트 재오픈이 아니라 `docs/findings/` 큐로.
- 동결 결정의 **근본 오류**가 늦게 드러나면 → findings가 아니라 **사용자 승인 후 `/grill` 재오픈**(Phase 1 재진입).
- 라우팅 기준: 단순 추가 / 충돌 → findings · 동결 결정 자체가 틀림 → grill 재오픈.

## 파일 형식 예시 (`docs/grill/checklist.md`)

각 항목에 렌즈 표기를 달아 4렌즈 스캔의 흔적이자 누락 렌즈 점검용으로 쓴다.

````markdown
# Grilling Checklist
<!-- 항목 입장: grounds-gate 3요소(특히 ground②). 동결 기능의 신규 기획거리는 findings로,
     동결 결정의 근본 오류는 grill 재오픈으로. -->

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
````
