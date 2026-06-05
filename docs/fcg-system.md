# FCG (findings-cycles-goals) 시스템 설명

자율 빌드 하네스의 핵심 — **findings → cycles → goals 3-자산 시스템** — 의 스택 중립 설명. 루핑 에이전트(Codex / Claude)가 매 iteration 동일 루프를 돌며 미션을 완수하게 한다. (원본: greatSumini/cc-system의 `findings-cycles-goals` 키트)

## 3-자산 모델

| 자산 | 무엇인가 | 검증 | 수명 |
|---|---|---|---|
| **findings** (`docs/findings/`) | out-of-scope 발견을 잃지 않는 부채/통찰 **큐** | 없음 | close 까지 |
| **cycles** (`cycles/`) | 무한 루프에 넘기는 한 세션 **프롬프트** | 없음 | 영구(이력) |
| **goals** (`goals/`) | gate로 검증되는 **영속 invariant** (goal당 3파일) | `.gates.sh` | 영구 |

**흐름:** iteration 중 발견한 부채 → **finding** 큐잉 → 사람이 **cycle** 문서를 써서 루핑 에이전트에 전달 → 에이전트가 finding들을 닫으며 일부를 **goal**로 promote → goal 하네스가 "완료"를 기계 검증.

**리뷰도 finding의 1급 출처다.** 회귀·계약 위반은 goal gate가 이미 기계 검증하므로, 사람의 리뷰는 검증이 아니라 소통·상호학습이다. 리뷰에서 나온 통찰을 finding으로 큐잉해야 루프가 닫힌다.

## 오케스트레이터 스크립트 (`scripts/`)

| 스크립트 | 역할 | 비용 |
|---|---|---|
| `diagnose.sh` | 매 iteration 첫 단계. git/active-goal/열린 finding/blocker read-only 출력 | sub-sec |
| `next-task.sh` | active goal의 `next-task.sh`로 dispatch (advisory hint) | sub-sec |
| `active-check.sh` | active goal gate + rigor sweep. green이면 completion-check로 exec | ~5–30s |
| `completion-check.sh` | 모든 goal gate 병렬 실행, 첫 실패를 `.state/active-goal`에 기록 | ~1–3분 |
| `check-gate-rigor.sh` | 메타-검증: universal claim ↔ enumerating gate 일치 | sub-sec |
| `_gate-cache.sh` | source 전용. gate 결과를 input fingerprint로 memoize (병렬 안전) | — |
| `update-state.sh` | `docs/state/{progress,next-task}.md` 재생성 | sub-sec |

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
| 목표 생성·게이트 루프·사이클 실행 | `/fcg-goal` | `bash scripts/{diagnose,active-check,completion-check}.sh` |
| finding 기록·정리 | `/fcg-findings` | `docs/findings/` 문서 작성 |
| cycle 문서 작성 | `/fcg-cycles` | `prompts/cycle-generate.md` + `docs/findings/` 취합 |
