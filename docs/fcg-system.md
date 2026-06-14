# FCG (findings-cycles-goals) 시스템 설명

자율 빌드 하네스의 핵심 — **findings → cycles → goals 3-자산 시스템** — 의 스택 중립 설명. 루핑 에이전트(Codex / Claude)가 매 iteration 동일 루프를 돌며 미션을 완수하게 한다. (원본: greatSumini/cc-system의 `findings-cycles-goals` 키트)

## 3-자산 모델

요지: **findings**(out-of-scope 발견 큐, 검증 없음, close까지) → **cycles**(무한 루프 한 세션 프롬프트, 검증 없음, 영구 이력) → **goals**(gate로 검증되는 영속 invariant, goal당 3파일, 영구). 전체 표·각 자산 상세는 `docs/goal-design.md` §"세 가지 자산: findings → cycles → goals"가 단일 출처.

**흐름:** iteration 중 발견한 부채 → **finding** 큐잉 → 사람이 **cycle** 문서를 써서 루핑 에이전트에 전달 → 에이전트가 finding들을 닫으며 일부를 **goal**로 promote → goal 하네스가 "완료"를 기계 검증.

**리뷰도 finding의 1급 출처다.** 회귀·계약 위반은 goal gate가 이미 기계 검증하므로, 사람의 리뷰는 검증이 아니라 소통·상호학습이다. 리뷰에서 나온 통찰을 finding으로 큐잉해야 루프가 닫힌다.

## 오케스트레이터 스크립트 (`scripts/`)

핵심 7종: `diagnose.sh`(매 iter 첫 단계, read-only 상태 출력) · `next-task.sh`(active goal로 dispatch) · `active-check.sh`(active goal gate + rigor sweep, green이면 completion-check exec) · `completion-check.sh`(모든 goal gate 병렬, 첫 실패를 `.state/active-goal`에 기록) · `check-gate-rigor.sh`(메타-검증: universal claim ↔ enumerating gate) · `_gate-cache.sh`(input fingerprint memoize, 병렬 안전) · `update-state.sh`(`docs/state/{progress,next-task}.md` 재생성). 각 스크립트 역할·비용 표는 `docs/goal-design.md` §`scripts/`(및 비용 모델 표)가 단일 출처.

> Windows에서는 Claude(Bash 도구)·Codex(셸) 모두 `bash scripts/<name>.sh` 형태로 호출한다(git-bash).

## 환경변수

| Env | 의미 | 기본 |
|---|---|---|
| `GATES_CONCURRENCY` | `completion-check.sh` 병렬 워커 수 (`0`→시리얼) | 4 |
| `GATES_SKIP_DEEP` | 외부/무거운 deep gate 스킵 (빠른 iteration) | completion-check 기본 1 |
| `GATES_NO_CACHE` | gate 캐시 우회 | — |
| `GATES_SKIP_META` | `_meta` goal을 sweep에서 제외 (CI가 이미 lint/test 돌릴 때) | — |

`.state/`(active-goal 포인터 + gate 캐시)는 런타임 생성물이며 **gitignore 대상**이다.

## 처음 읽을 순서

1. `docs/goal-design.md` — 왜 이렇게 설계됐는가 (§1, §1.5, §5).
2. `guidelines/goal-iteration.md` — 한 iteration을 어떻게 도는가.
3. 각 폴더의 `AGENTS.md` — findings / cycles / goals 규약.

## 슬래시 스킬과의 매핑

| 작업 | 전역 스킬 | 구동 |
|---|---|---|
| 목표 생성·게이트 루프·사이클 실행 | `/build` | `bash scripts/{diagnose,active-check,completion-check}.sh` |
| finding 기록·정리 | `/fcg-findings` | `docs/findings/` 문서 작성 |
| cycle 문서 작성 | `/fcg-cycles` | `prompts/cycle-generate.md` + `docs/findings/` 취합 |
