# 프로젝트 템플릿 — Claude(기획) + GPT(구현) + FCG 하네스

새 프로젝트를 시작할 때 **이 폴더를 통째로 복사**해 쓰는 템플릿이다. 폴더에는 FCG(findings-cycles-goals) 자율 빌드 하네스의 **자산**(scripts·goals·cycles·docs 구조·규약)이 들어 있다. 단, 워크플로우 **스킬은 전역 설치본**이라 폴더 복사로는 따라오지 않는다 — 새 머신/유저라면 아래 [필수 전역 스킬](#필수-전역-스킬-먼저-설치)을 먼저 깔 것.

## Tips
- 터미널 깨졌을때 : ctrl+shift+P -> reload window 로 새로고침 (세션 유지됨)
- 문서관리 팁 : Frontmatter 활용 (title / created at / resolved (true/false) / status_notes(상태요약) / related(관련문서) ). 단, 문서 유형별 정확한 스키마는 각 폴더의 `AGENTS.md`가 단일 출처 — findings·spec은 `resolved:`, issues는 `Status:` 라벨, cycles는 `status:` 단계값을 쓴다.
- 병렬 작업 : 세션 컨텍스트 유지하면서 병렬 처리할게 있으면, /branch 기능으로 해당 세션 복제 후 병렬로 일 시키는게 빠르고 토큰 효율적
- 주기적 Spec 문서 관리 : 코드가 수정되었는데 스펙이 구버전이면 나중에 ai가 이걸 읽고 엉뚱한 코드를 짤 수 있음. 의식적으로 /spec-sync 스킬을 통해 계약문서(spec)을 업데이트 할 필요가 있음.

## 필수 전역 스킬 (먼저 설치)

이 폴더는 FCG **자산**(scripts·goals·cycles·docs 구조·규약)만 담는다. 워크플로우의 **스킬(동사)** 은
전역 설치본이라 폴더 복사로는 따라오지 않는다. 같은 머신에서 계속 쓰면 이미 깔려 있지만, **새 머신/유저**에서
처음 셋업한다면 아래가 있어야 워크플로우가 발동한다.

| 단계 | 스킬 | 설치 위치 |
|---|---|---|
| Phase 1 (기획·계약) | `grill-with-docs` · `prototype` · `to-prd` · `to-issues` · `to-spec` · `handoff` | `~/.claude/skills/` |
| Phase 2 (구현) | `fcg-goal` · `fcg-findings` · `fcg-cycles` | `~/.claude/skills/`(Claude) · `~/.codex/skills/`(Codex) |
| Phase 2·2.5 (보조·정비) | `tdd` · `improve-codebase-architecture` · `spec-sync` | `~/.claude/skills/` |

**설치 (새 머신·배포 시)** — `git clone` 후 한 번: `bash scripts/install-skills.sh` (bespoke를 전역에 설치하고, 공개 스킬 설치법을 출력).

**출처**
- **Matt Pocock 스킬셋**(github.com/mattpocock/skills): grill-with-docs · to-prd · to-issues · prototype · tdd · improve-codebase-architecture · handoff.
- **FCG 하네스**(github.com/greatSumini/cc-system): fcg-goal · fcg-findings · fcg-cycles. 그 레포의 `prompt/install-findings-cycles-goals.md`로 설치한다.
- **이 템플릿 전용(bespoke)**: `to-spec` · `spec-sync` — `docs/spec` 계약 규약 전용으로 만든 것이라 **공개 install 출처가 없다.** 소스는 레포 `skills/`에 백업돼 있고, `scripts/install-skills.sh`가 전역(`~/.claude/skills/`)으로 설치한다.

> 확인: Claude는 `~/.claude/skills/`, Codex는 `~/.codex/skills/`에 위 스킬 폴더가 있는지 본다.
> 이 폴더의 `.claude/skills/`는 **프로젝트 전용** 슬롯이며 전역 스킬과 구분된다. 현재 `roadmap/`
> (로컬 로드맵 대시보드) 하나가 들어 있다 — 이 워크플로우 시스템이 갖춰져야만 동작하므로
> 전역이 아닌 프로젝트 전용으로 둔다(`scripts/template-clean-check.sh`가 필수 산출물로 강제).

## 빠른 시작

1. 이 폴더를 새 프로젝트 경로로 복사한다.
2. `bash scripts/reset-for-new-project.sh` — 복사로 따라온 머신-로컬/생성 상태(`.state/`·자동생성 state·이전 사용자의 `.claude/settings.local.json`)를 비운다. (`git clone`으로 받았다면 불필요.)
3. `git init` (선택) 후 작업 시작.
4. **Claude**로 기획: `/grill-with-docs` → `/to-prd` → `/to-issues` → `/to-spec` → `/handoff`
5. **GPT(Codex)**로 구현: 첫 `/fcg-goal`(변환 모드 B)이 이슈/PRD를 `goals/<n>-*` 실행계약으로 바꾸며, `goals/AGENTS.md` 부트스트랩 규약에 따라 `goals/0-example.*`를 제거하고 실제 goal로 교체한다 → 이후 `/fcg-goal`로 게이트를 green으로, `/fcg-findings`·`/fcg-cycles`로 부채 관리.
6. `goals/0-example.*`는 워크플로우를 이해하기 위한 **교육용 예제**다 — 위 첫 변환이 규약대로 제거·교체하므로 손으로 지울 필요는 없다(원하면 직접 지워도 됨).

## 워크플로우 (상세)

> 모델은 각 스킬을 설명만으로 자동 발동한다. 아래 순서는 **사용자가 직접 호출하는** 기준이다.

> ⚠️ **모델별 스킬 호출 방식이 다르다.**
> - **Claude(기획)**: 슬래시 명령 그대로 — `/grill-with-docs`, `/to-prd`, `/fcg-goal` …
> - **Codex/GPT(구현)**: **슬래시(`/fcg-goal`)는 안 먹는다.** Codex는 fcg 스킬을 `~/.codex/skills/`에
>   자동발동형으로 갖고 있으므로 **자연어로 트리거**한다 — 예: `"fcg-goal 돌려줘"`,
>   `"PRD를 goals 계약으로 변환해줘"`, `"cycles/<파일>.md 완수까지 작업해줘"`, `"이건 범위 밖이니 finding으로 적어둬"`.
>   (Codex의 custom-prompt 슬래시는 deprecated이고 0.136.0 기준 메뉴에 노출되지 않는다. 자연어 발동이 정식 경로다.)
> - 아래 표기는 **개념적 단계명**이다. Codex로 구현할 땐 그 단계의 의도를 자연어로 말하면 같은 스킬이 발동한다.

### Phase 1 — 기획 (Claude)

**스킬 흐름**

```
/grill-with-docs   → CONTEXT.md, docs/adr/        (도메인 모델·용어·결정)
/prototype         → (필요시) 데이터모델/UI 스파이크
/to-prd            → docs/prd/PRD.md
/to-issues         → docs/issues/NNN-*.md          (PRD를 수직 슬라이스 "목록"으로)
/to-spec           → docs/spec/*.md + INDEX.md     (계약 고정 — 구현의 단일 진실원천)
/handoff           → 구현 모델로 인계 (계약 고정 후 Phase 1 마무리)
```

> ⚠️ `grill-with-docs`에만 의존하지 말고, 아래 항목이 구체화되었는지 확인할 것:
> 1. 구현가능성
> 2. 기술 스택
> 3. 사용 흐름(Usecase)
> 4. 화면 설계
> 5. API 설계
> 6. 데이터 스키마 설계
> 7. 코드 아키텍쳐 설계

위 항목이 결정되면 문서를 **성격에 따라 갈라 둔다**:

- **계약문서(`docs/spec/`)** = 코드가 반드시 따르는 안정 인터페이스 → 5)API·6)데이터 스키마·공개 타입.
  `/to-spec`이 accepted ADR+PRD에서 추출해 생성한다(이 Phase 1 끝의 `/to-spec` 단계 — 아래). PRD·ADR보다 우선하는 단일 진실원천.
- **설계문서(`docs/design/`)** = 강제력 약한 산출물 → 3)흐름(flow.md)·4)화면(screens.md)·7)아키텍처(architecture.md).
- **결정 이력(`docs/adr/`)** = 기획/구현 중 기술적 결정이 바뀔 때마다 한 결정 한 파일로 기록.

#### `/to-spec` — 계약 고정 (Phase 1 마무리 산출)

- **무엇을:** accepted ADR + PRD + CONTEXT 용어를 읽어 `docs/spec/`에 data-schema·api-contract·domain-types
  등 **계약문서**와 `docs/spec/INDEX.md`를 **처음 생성**한다.
- **왜:** 구현 모델이 단일 진실원천으로 **최우선 참조**하는 안정 인터페이스를 한 곳에 모은다. PRD·ADR보다 우선한다.
- **언제:** `/to-issues` 직후, **`/handoff` 직전**. 구현 모델이 인계받자마자 `docs/spec/INDEX.md`를
  최우선으로 읽으므로, 계약은 handoff 전에 고정돼야 한다.
- **생성 vs 유지:** to-spec은 "생성"만. 생성된 계약은 이후 Phase 2.5의 `/spec-sync`가 코드·ADR과 정합 유지한다.

### Phase 1 → 2 경계 — 변환

> Phase 1 끝에서 `/to-spec`으로 계약을 이미 고정했다. 경계에서 남은 일은 **변환** 하나다.

**스킬 흐름**

```
/fcg-goal   # docs/issues/*.md(또는 PRD)를 goals/<n>-*.{md,gates.sh,next-task.sh} 실행계약으로
```

> `/fcg-goal`(변환 모드 B)이 이슈/PRD를 **3파일 실행계약**으로 만든다. handoff 이후 구현 모델이 직접 돌려도 된다.
> to-issues 슬라이스 "목록" ≠ FCG goal "3파일 실행계약" ≠ spec "계약 인터페이스" — 셋은 층위가 다르다.

### Phase 2 — 구현 (GPT 주력)

> Codex에서는 **슬래시가 아니라 자연어로** 발동한다(위 ⚠️ 참조).

**스킬 흐름**

```
bash scripts/diagnose.sh                              # 매 시작: active-goal·열린 finding·blocker
"fcg-goal 돌려줘"                  → active goal의 .gates.sh를 green으로 (TDD 규율 내장, 끝까지 자율 실행)
"이건 범위 밖이니 finding으로 적어둬"  → 범위 밖 발견을 docs/findings/ 큐잉 (fcg-findings)
"쌓인 findings 묶어서 cycle 만들어줘"  → cycles/<YYMMDD>-NN-*.md 로 묶기 (fcg-cycles)
"cycles/<cycle>.md 의 내용을 모두 완수할 때까지 작업해줘"   # cycle = 진입 문서, fcg-goal 사이클 모드
```

> (Claude로 같은 단계를 돌릴 땐 `/fcg-goal`, `/fcg-findings`, `/fcg-cycles` 슬래시도 그대로 동작한다.)

#### `/fcg-goal` — 상황별 사용법

`/fcg-goal`은 단일 엔진이 **입력 종류로 모드를 자동 판별**한다. "변환"과 "구현"에 같은 스킬을 써도 되는 이유이자, 셋 다 같은 `goals/` 자산·게이트 계약 위에서 돌기 때문이다.

| 상황 | 주는 입력 | 모드 | 결과 |
|---|---|---|---|
| issues/PRD를 실행계약으로 변환 | `/fcg-goal docs/issues/*.md` (또는 `docs/prd/PRD.md`) | **B. 변환** | 각 수직 슬라이스 → `goals/<n>-*.{md,gates.sh,next-task.sh}` 3파일 계약 생성 |
| active goal 구현 | `/fcg-goal` (입력 없음) 또는 `/fcg-goal goals/<n>-*.md` | **A. 게이트 루프** | active goal을 RED→GREEN으로 green화, green이면 다음 goal로 자동 전진 |
| cycle 무인 실행 | `/fcg-goal cycles/<파일>.md` | **C. 사이클 실행** | driver 문서대로 findings를 소진까지 처리(조기 종료 금지, 3회 무진전 시 `blockers.md` 기록) |

> 입력이 곧 모드 선택이다. 변환을 원하면 이슈/PRD 경로를 명시하고, 구현을 원하면 그냥 부른다.
> (변환 모드 B는 개념적으로 [Phase 1 → 2 경계](#phase-1--2-경계--변환)에서 쓰지만, 같은 엔진이라 여기 함께 정리한다.)

#### `/tdd` — `/fcg-goal`과의 관계 (택일 아님, 층위 다름)

- **TDD 규율은 `/fcg-goal`에 이미 내장**돼 있다(`goal-iteration.md` Phase 4: RED 커밋 → GREEN 커밋 → REFACTOR).
  즉 `/fcg-goal`만 돌려도 TDD로 진행된다. **`/fcg-goal`은 `/tdd` 스킬을 자동 호출하지 않는다** — 두 스킬 중
  하나만 고르는 관계가 아니라, fcg-goal이 자율 드라이버이고 tdd는 그 곁에서 쓰는 보조다.
- **`/tdd`를 별도로 쓰는 상황:**
  - 테스트 설계가 까다로운 기능에서 **"어떻게 좋은 테스트를 설계하나"**의 깊이가 필요할 때 (behavior-over-implementation, deep modules, 인터페이스 설계, mocking 가이드, 수직 슬라이스 안티패턴)
  - goal 루프 **밖**에서 test-first로 작업할 때 (Phase 1 프로토타입, 단발성 버그 수정 등)
- **얻는 결과:** 구현 detail이 아니라 공개 인터페이스/동작을 검증하는 — 리팩토링에도 살아남는 — 테스트. `goal-iteration.md`의 TDD 절차가 "어떻게 도는가"라면, `/tdd`는 "무엇을·왜 그렇게 테스트하나"를 보강한다(점검은 `prompts/check-test-codes/`, `guidelines/품질점검.md`).

#### `/fcg-findings` — 자동(에이전트) + 수동(사용자) 두 경로

- **자동(루프 중 에이전트 주도):** `/fcg-goal` 루프(특히 사이클 모드) 중 에이전트가 **현재 goal 범위 밖의 부채·버그·추가요구를 발견하면**, 그 자리에서 고치지 않고 `/fcg-findings`로 `docs/findings/`에 큐잉한다. 이것이 scope creep을 막아 루프를 집중시키는 핵심 메커니즘이다(`AGENTS.md` invariant: "범위 밖이면 고치지 말고 기록").
  > ⚠️ **주의 — scope가 명확해야 작동한다.** goal `.md`의 Mission/forbidden-actions가 모호하면 에이전트가 곁가지를 그냥 고쳐버려(scope creep) finding이 남지 않는다. 자동 큐잉의 전제는 또렷한 goal 경계다.
- **수동(사용자 주도):** 기획/구현 중 추가 작업을 발굴했을 때 사용자가 직접 "이건 지금 하지 말고 finding으로 적어둬"라고 지시할 수 있다. 리뷰 대화에서 나온 통찰도 finding의 1급 출처다. (병렬 세션에서 한 세션이 다른 작업을 발굴하면 finding으로 남기는 운영이 대표적.)

### Phase 2.5 — 아키텍처 정비 (주기적, cycle 사이)

**스킬 흐름**

```
/improve-codebase-architecture   → 얕은(shallow) 모듈·deepening 후보를 HTML 리포트로 발굴
                                   (CONTEXT.md 도메인어 + docs/adr/ 결정 기반)
  → 채택한 후보를 /fcg-findings 로 docs/findings/ 큐잉 → /fcg-cycles → /fcg-goal 로 실행
/spec-sync                       → 계약 스펙(docs/spec/) ↔ 코드 ↔ 최신 accepted ADR 드리프트 점검·정합
                                   (문서만 고치면 됨 → 직접 갱신 / 코드 고쳐야 함 → finding 큐잉 / 모호 → 질문)
```

> 리팩토링 "발굴 → finding → cycle → goal" 파이프라인. 코드/스펙 드리프트를 주기적으로 흡수한다.
> 스펙 권위·우선순위 규약은 `AGENTS.md`의 "Spec authority" 섹션. PRD/ADR은 재작성하지 않는다(계약 스펙만 정합).

---

두 모델이 같은 `docs/`·`goals/`·`cycles/`를 공유 → 전환은 `/handoff` 하나. FCG 상세: `docs/fcg-system.md`.

## 템플릿 폴더 설명

| 경로 | 용도 |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | 작업 규약 진입점 (GPT·범용 / Claude) |
| `CONTEXT.md` (루트) | 도메인 용어집(glossary). `/grill-with-docs`가 첫 용어 확정 시 lazy 생성. AGENTS.md 읽기순서 2번 |
| `docs/prd/` | `/to-prd` 산출 PRD |
| `docs/issues/` | `/to-issues` 산출 수직 슬라이스 목록(local) |
| `docs/adr/` | `/grill-with-docs` 산출 ADR (결정 이력, append-only) |
| `docs/spec/` | `/to-spec` 산출 **계약문서**(data-schema·api-contract·domain-types + INDEX.md). 구현의 단일 진실원천, `/spec-sync`가 유지 |
| `docs/design/` | 비계약 **설계문서**(flow·screens·architecture). 권위 없음, 구현 참고용 |
| `docs/agents/` | 엔지니어링 스킬용 설정 스텁(이슈트래커·triage라벨·도메인). 단일 진실원천은 `AGENTS.md` |
| `docs/findings/` | FCG 부채/통찰 큐 |
| `docs/archive/findings/` | append-only-log 성격 finding의 분기별 아카이브 (`docs/findings/AGENTS.md` Lifecycle §Archive) |
| `docs/state/` | 진행 상태. `progress.md`·`next-task.md`(자동생성, gitignore) + `blockers.md`·`learnings.md`·`test-plan.md`(append-only·리빙큐) |
| `docs/fcg-system.md` | FCG 3-자산 모델 설명 |
| `docs/goal-design.md` | goal 설계 노트 |
| `goals/` | FCG 미션 스택 (`<n>-*.{md,gates.sh,next-task.sh}`) |
| `cycles/` | FCG loop-driver 프롬프트 |
| `scripts/` | FCG 오케스트레이터 셸스크립트 + `install-skills.sh`(스킬 설치) + `reset-for-new-project.sh`(복사 후 머신-로컬 상태 초기화) |
| `dashboard/` | 로컬 로드맵 대시보드. `engines/roadmap.sh`(이슈·active goal·goal 계약 → self-contained `roadmap.html` emit, gitignore) + `engines/roadmap-selftest.sh` + `README.md`. `/roadmap` 스킬로 호출 |
| `guidelines/` | iteration 운영 매뉴얼 + 품질점검 체크리스트 |
| `prompts/` | 메타 프롬프트 — `cycle-generate.md`(사이클 문서 생성) + `check-test-codes/`(테스트코드 점검 지침) |
| `skills/` | 배포용 **bespoke 스킬 소스**(to-spec·spec-sync). `scripts/install-skills.sh`가 `~/.claude/skills/`로 설치(전역 실행 유지 + 레포 백업) |
| `.claude/skills/` | 이 프로젝트 **전용** 스킬(전역 스킬과 구분). 현재 `roadmap/` 하나 — 워크플로우 시스템 의존이라 전역 아닌 프로젝트 전용이며 `template-clean-check.sh`가 필수로 강제. 기획·구현·계약 스킬은 모두 전역(`~/.claude`·`~/.codex`). 프로젝트 한정 패턴이 반복 증명되면 추가 |
## Worktree Safety

Generated dashboard output is not proof that the current worktree is clean or
complete. Before sharing or using the roadmap as a status artifact, run
`bash scripts/completion-check.sh` and review the current worktree state.
