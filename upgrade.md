# upgrade.md — ironman 워크플로우 시스템 업그레이드 실행계획

> migration 스킬(요구1) · 플러그인 배포 + `/ironman:init`(요구2) · `/ironman:help` 스킬(요구3).
> 작성 2026-06-16, 내일 실행 예정. 결정사항은 아래 Context에 고정 — 실행 중 재논의 불필요.
> 동반 사본: `C:\Users\lsc95\.claude\plans\hazy-churning-ripple.md`.

## Context (왜)

현재 `project_template_mpfcg`는 **새 프로젝트 시작 시 템플릿 폴더를 복사-붙여넣기**해야 하고, 기존 코드베이스를 온보딩하는 길이 없으며, "지금 어디까지 왔고 다음에 뭘 해야 하는지" 안내 장치가 없다. dryforge / bmad-test를 참고해 세 구멍을 메운다:

1. **migration 스킬** — dryforge `/migration`처럼 기존 코드베이스를 스캔·elicit해서 하네스 문서를 채우는 1회성 온보딩.
2. **터미널 설치 명령** — 복붙 대신 명령 한 줄로 새/기존 프로젝트에 설치. **Claude Code 플러그인 배포**(dryforge와 동일 형식, `/plugin update`로 갱신 용이).
3. **help 스킬** — bmad-help처럼 상태를 읽어 "현 위치 + 다음 스킬"을 안내(+워크플로우 일반 Q&A).

**확정 결정:**
- **브랜드 = `ironman`** (우산 이름). `FCG(findings-cycles-goals)`는 **goal-engine 서브시스템 용어로 존치** — 전면 개명 아님. ironman = Matt Pocock 기획 워크플로우 + cc-system FCG 결합.
- **레포·폴더 개명: `project_template_mpfcg` → `project_workflow_ironman`** (GitHub 레포 + 로컬 폴더 둘 다). Claude 메모리 폴더도 이전해 연속성 유지.
- **배포 = 혼합형 Claude Code(+Codex) 플러그인.** 플러그인에는 lifecycle 스킬만 둔다(`/ironman:init`·`/ironman:help`·`/ironman:migration`). 매일 쓰는 스킬은 `/ironman:init`이 전역 skill home에 설치해 짧은 명령(`/concept`·`/freeze`·`/build` 등)을 보존한다.
- **설치/동기화 명령 = `/ironman:init`**. 첫 설치와 업데이트 후 재동기화를 모두 맡는다. 자산 트리를 cwd로 스캐폴딩하고, `scripts/install-skills.sh --force`로 Claude/Codex 전역 스킬과 Codex slash shim을 갱신한다.
- **migration 범위 = 린(FCG 하네스만 채움)** — 산출물: `AGENTS.md §Architecture/§Context` 채우기 + 루트 `CONTEXT.md` 생성 + 확정 트레이드오프 `docs/adr/` 시드. **새 문서 분류 안 만듦**(doc-hygiene 준수).
- **help 범위 = 라우터 + 워크플로우 Q&A.** 명령 = `/ironman:help`.

**핵심 플로우 (dryforge 대응):**
```
dryforge:  /plugin install   →  /migration              →  /ready → /go
ironman :  /ironman:init      →  /ironman:migration        →  /concept → /freeze → /build
           └ 구조(자산) 복사       └ 코드 읽고 하네스 *내용* 채움
```
그리니필드면 migration 생략(`/ironman:init` → `/concept`). 막히면 `/ironman:help`.

---

## Build order (무엇을 먼저)

의존: **플러그인 섀시(B)**가 init/migration/help가 꽂히는 토대. 브랜드(A-content)는 플러그인·명령 이름이 참조하므로 선행. **물리적 개명(A-rename: GitHub/폴더/메모리)은 세션 cwd를 깨므로 마지막 컷오버**로 분리.

| 순서 | Phase | 내용 | 요구 |
|---|---|---|---|
| 1 | **A. 리브랜드(콘텐츠)** | 루트 `README.md` 신설(크레디트+소개), 진입점·가이드에 ironman 우산 이름 도입(FCG 용어 유지) | 2 토대 |
| 2 | **B. 플러그인 섀시** | 레포를 플러그인 레이아웃으로 — marketplace.json + plugin.json(Claude+Codex), lifecycle skills→플러그인, daily skills→assets+전역 설치, dryforge식 build/parity | 2 |
| 3 | **C. `/ironman:init`** | 스캐폴더 명령: 번들 자산을 cwd로 복사(그리니필드=새로/브라운필드=백업 후 덮기), baseline 기록, 다음 단계 안내 | 2 |
| 4 | **D. `migration` 스킬** | 브라운필드 내용 채움(SCAN→ELICIT→GENERATE 린→독립 REVIEW→GATE) | 1 |
| 5 | **E. `/ironman:help` 스킬** | 라우터(diagnose.sh+Phase1 상태) + 가이드 근거 Q&A | 3 |
| 6 | **F. 통합·도그푸드** | 가이드/진입점 갱신, 그리니필드+브라운필드+플러그인 설치/업데이트 테스트 | — |
| 7 | **A-rename. 물리 컷오버** | GitHub 레포 개명 + remote 갱신 + 로컬 폴더 rename + 메모리 폴더 이전 + 전역 스킬 정리 | 2 |

> **요점: 먼저 할 일 = A(리브랜드 콘텐츠) → B(플러그인 섀시).** 섀시가 서면 C/D/E가 그 위에 꽂힌다. E(help)는 라우팅 표가 init/migration까지 포함해야 하므로 마지막 스킬. 물리 개명은 컷오버로 맨 끝.

---

## Phase A — 리브랜드 (콘텐츠)

- **신설 `README.md`** (GitHub 랜딩 전용 — dryforge README처럼 플러그인엔 미번들). 최상단 크레디트:
  > 본 워크플로우 시스템은 Matt Pocock의 기획 워크플로우와 cc-system의 findings-cycles-goals 시스템을 조합한 시스템이다.
  이어서 시스템 1단락 소개 + 설치(`/plugin marketplace add …` → `/plugin install ironman`) + 플로우(`/ironman:init`·`/ironman:migration`·`concept→freeze→build`·`/ironman:help`).
  - 메모리상 README는 과거 의도적 삭제(가이드로 일원화)였음 → 이번엔 **GitHub 랜딩+크레디트 전용**으로 목적 분리해 부활(가이드와 역할 안 겹침).
- **브랜드 도입**: `AGENTS.md`·`CLAUDE.md` 헤더, `Workflow_Guideline_v1.html` 1탭에 "ironman = 우산 시스템(MP기획 + cc-system FCG)" 한 줄. **FCG 용어·`docs/fcg-system.md`·스크립트·메모리는 그대로**(전면 개명 아님).

## Phase B — 플러그인 섀시 (dryforge 구조 참고)

dryforge 검증 레이아웃: `src/skills/`(단일 소스) → `build.sh` → `claude/`·`codex/plugin/`(빌드 산출, 커밋) + 루트 `.claude-plugin/marketplace.json`·`.agents/plugins/marketplace.json`.

- **마켓플레이스 매니페스트**: 루트 `.claude-plugin/marketplace.json`(Claude) + `.agents/plugins/marketplace.json`(Codex). `plugins[].name = ironman`, `source` = 플러그인 디렉토리(`./경로` 또는 github 객체).
- **플러그인 디렉토리**: `plugin.json` + `skills/`(lifecycle 3종: init/help/migration) + **번들 자산 트리**(`assets/workflow/` = `/ironman:init`이 cwd로 복사할 하네스 + daily `skills/`) + **`bin/ironman-init`** self-locating 실행파일.
- **자산 목록의 단일 소스 = 기존 `workflow-manifest.txt`** 재사용(무엇을 번들/스캐폴딩할지).
- **Claude+Codex parity**: dryforge `build.sh` 패턴 차용(단일 소스 → 두 플랫폼 빌드, 버전 일관성 가드). ⚠ **Codex 플러그인 메커니즘은 Anthropic 공식문서에 없음** — dryforge의 실제 `.agents/plugins/marketplace.json`+`codex/plugin/`(`.codex-plugin/plugin.json`+`agents/openai.yaml`) 구조를 **정본 예시**로 차용. self-locating bin(아래 C)이 plugin-root 변수에 비의존이라 이식 안전. Phase F에서 실제 Codex 설치로 검증.
- **명령 표면**: 플러그인 lifecycle은 네임스페이스 강제 → `/ironman:init`·`/ironman:help`·`/ironman:migration`. Daily skills는 `/ironman:init`이 전역 설치하므로 `/concept`·`/freeze`·`/build`·`/finding`·`/cycle`·`/handoff`·`/prototype`·`/spec-sync`·`/improve-codebase-architecture`, 프로젝트 local `/roadmap`으로 사용한다.
- **번들 자산 (확인됨)**: 플러그인은 `assets/`·`scripts/`·`bin/` 등 임의 파일 번들 가능(설치 시 캐시로 복사). 버전은 **생략**(활발 개발 → 매 push가 업데이트로 인식), 안정화 시 `plugin.json`에 명시.

> ⚠ **자산 배치**: 플러그인은 어차피 캐시로 복사되므로 `assets/` 번들이 깔끔. 자산 목록 단일 소스는 기존 `workflow-manifest.txt` 유지. (repo 루트=라이브 프로젝트 도그푸드성은 플러그인 채택으로 비중↓ → scratch 폴더 `/ironman:init`으로 대체 검증.)

## Phase C — `/ironman:init` (스캐폴더, 요구 2)

- 동작: 대상(cwd) 판별 → 자산 복사/갱신(기존 파일은 `.ironman/backup/<timestamp>/`에 백업) → daily `skills/` 소스 복사 → `scripts/install-skills.sh --force` 실행 → `.ironman/status` 기록 → 다음 단계 안내.
  - **브라운필드 충돌**: 대상에 기존 `CLAUDE.md`/`AGENTS.md`가 있으면 dryforge식으로 **백업 후 덮기**(`.ironman/backup/` 등). git 없으면 `git init` 제안.
  - 안내 분기: 그리니필드 → `/concept`; 브라운필드(외부 코드 있음) → `/ironman:migration`.
- **메커니즘 (claude-code-guide 확인 반영 — 중요)**: `${CLAUDE_PLUGIN_ROOT}`는 **hook/MCP/bin 컨텍스트에서만** 치환되고 **스킬/명령 마크다운 본문에선 못 씀**. 그래서 스캐폴딩 로직을 **플러그인 `bin/` 실행파일**(플러그인 활성 시 Bash PATH에 올라감)로 싣고, 그 스크립트가 **자기 경로 기준으로 번들 `assets/`를 self-locate**(`SCRIPT_DIR/../assets`)해 복사한다 — env-var 비의존 → **Codex에도 이식 가능**. `/ironman:init` 스킬(`disable-model-invocation: true`)은 이 bin을 호출하는 얇은 래퍼.
- **재사용(신규 코드 최소화)**: daily skill 설치는 기존 `scripts/install-skills.sh --force`가 맡는다. 업데이트 흐름은 plugin update/marketplace refresh 후 `/ironman:init`을 다시 실행해 하네스와 전역 스킬을 함께 동기화한다.

## Phase D — `/ironman:migration` 스킬 (요구 1, 린)

신규 `src/skills/migration/SKILL.md` + `references/`. dryforge migration의 **방법**을 이식하되 **FCG 하네스에만** 산출:

- **전제 체크**: ironman 구조 존재(예: `scripts/diagnose.sh`/`goals/AGENTS.md`)·기존 코드·git. 구조 없으면 "`/ironman:init` 먼저", 그리니필드면 "`/concept`로" 안내.
- **SCAN**: 코드 인라인 정독 → 모듈/엔티티·패턴·보안면·외부의존·갭의 **원장(ledger)**.
- **ELICIT**: 위험가중(추론 우선, 틀리면 위험한 것[비즈니스모델·도메인 불변식·보안정책]만 깊게 확인). 원장 전 항목 `confirmed/asked-answered/N/A-사유`로 닫힘. dryforge `migration-elicit.md` 이식(스택·언어 불문, 네이티브 언어 출력).
- **GENERATE (린 타깃)**: `AGENTS.md §Architecture/§Context` 채움 + 루트 `CONTEXT.md`(용어집) 생성 + 확정 트레이드오프 `docs/adr/<NNNN>-*.md` 시드. **포맷은 기존 `skills/concept/CONTEXT-FORMAT.md`·`skills/concept/ADR-FORMAT.md`를 인용**(doc-hygiene: 재서술 금지, one-canonical-home). 새 문서 taxonomy 안 만듦.
- **REVIEW**: 작성 안 한 **독립 general-purpose 서브에이전트 1명**이 ironman 하네스 루브릭(`references/harness-review.md`, dryforge 이식+FCG 맞춤)으로 검증. 이 스킬 유일 dispatch.
- **GATE**: 핵심 결정 walk-through → 승인. **커밋 안 함**(사용자 몫). 완료 후 세션 클리어 → `/concept`(신규 기능) 또는 `/build`(이슈 존재).
- 참조 파일: `references/migration-elicit.md`(이식), `references/harness-review.md`(이식+맞춤). harness-format은 concept의 기존 포맷 문서 인용으로 대체(중복 회피).

## Phase E — `/ironman:help` 스킬 (요구 3, 라우터+Q&A)

신규 `src/skills/help/SKILL.md`:

- **상태 감지**: `bash scripts/diagnose.sh`(Phase 2: active goal·findings·spec drift·issue graph·next-task) + Phase 1 직접 판독(`docs/design/checklist.md` 닫힘 슬롯 [x]/[~]/[>], `docs/prd/PRD.md`, `docs/spec/INDEX.md`, `docs/issues/*.md`, `goals/` 0-example만=미변환).
- **라우팅 표 (FCG 상태머신)**:
  - 구조 없음 → `/ironman:init`
  - 브라운필드(§Arch/§Context 비었고 외부 코드 있음) → `/ironman:migration`
  - 결정표면 열림 → `/concept`
  - concept 체크리스트 전부 닫힘 → `/freeze`
  - 이슈 있고 goal 미변환 → `/build`(mode B 변환)
  - active goal 실패 중 → `/build`
  - ALL_DONE + 열린 findings → `/cycle` → `/build cycles/<f>.md`
  - 세션 전환 직전 → `/handoff`
- **Q&A 모드**: "freeze가 뭐 해?" 류 일반 질문은 `Workflow_Guideline_v1.html`(정본 워크플로우 레퍼런스) + 스킬 description 근거로 답하고 인용.
- **출력**: 사용자 언어, "현 위치 + 다음(필수 1개·선택지) + 실행법 + 지금 실행해줄까?"(bmad-help식). 카탈로그 덤프 금지(관련 것만). 구조 없으면 우아하게 `/ironman:init` 권고.

## Phase F — 통합·도그푸드

- `Workflow_Guideline_v1.html`(스킬 사전·업데이트 탭)·`AGENTS.md`·`CLAUDE.md`에 신규 3장치(init/migration/help) + 혼합형 플러그인 설치/업데이트 절차 반영. 크레디트 푸터 유지.
- **테스트**: ① 빈 scratch 폴더 → `/ironman:init` → 자산·baseline 확인 → `/concept` 작동. ② 토이 외부 레포 → `/ironman:init` → `/ironman:migration` → AGENTS.md/CONTEXT.md 채워짐 + 독립 REVIEW 통과. ③ `/plugin marketplace add … → install ironman` → 명령 노출 → `/ironman:help` 라우팅. ④ push 후 `/plugin update` 또는 marketplace refresh. ⑤ Codex parity 실설치. ⑥ 기존 self-test(roadmap 등)·`scripts/*` 회귀.

## Phase A-rename — 물리 컷오버 (맨 끝)

- GitHub 레포 개명 → `project_workflow_ironman`(`gh repo rename`, **사용자 확인 후**) + `git remote set-url`.
- 로컬 루트 폴더 rename(세션 cwd 깨짐 → **별도/사용자 수행 단계**).
- Claude 메모리 폴더 이전: `…\projects\C--00-EVERBUILD-project-template-mpfcg\` → `…\C--00-EVERBUILD-project-workflow-ironman\`(연속성).
- **전역 스킬 정리**: 혼합형에서는 전역 daily skills가 의도된 표면이다. `/ironman:init`이 이전 명령명의 전역 skill과 slash shim을 제거하고 `/concept`만 canonical 표면으로 둔다.

---

## Verification (전체 E2E)

- 그리니필드: `mkdir scratch && cd scratch` → `/ironman:init` → `ls`로 자산 트리·`.workflow-version` 확인 → `bash scripts/diagnose.sh` 정상 → `/concept` 진입.
- 브라운필드: 외부 토이 repo 복제 → `/ironman:init`(기존 CLAUDE.md 백업 확인) → `/ironman:migration` 완주 → `AGENTS.md §Architecture/§Context`·`CONTEXT.md` 내용 채워짐, 독립 REVIEW 무차단.
- 플러그인: 렌더 후 marketplace add/install → `/ironman:init`·`/ironman:help`·`/ironman:migration` 노출 → push 후 plugin update/marketplace refresh → `/ironman:init` 재실행으로 daily skills까지 반영.
- 회귀: 기존 `scripts/` 게이트·dashboard self-test 무손상.

## Resolved — 플러그인 메커니즘 (claude-code-guide 검증 완료, 공식문서 인용)

- **임의 자산 번들 ✅** — `assets/`·`bin/`·`scripts/` 등 자유. 설치 시 캐시(`~/.claude/plugins/cache/...`)로 복사.
- **`${CLAUDE_PLUGIN_ROOT}` ✅ 단 제약** — hook/MCP/LSP/monitor·plugin.json 치환에서만 사용 가능, **스킬 마크다운 본문에선 불가**. → 그래서 **self-locating `bin/` 실행파일** 설계(Phase C). (`${CLAUDE_PLUGIN_DATA}`=업데이트 후에도 보존되는 상태 폴더, 필요시.)
- **마켓플레이스 ✅** — 깃 레포+`.claude-plugin/marketplace.json`. 비공개 레포 OK(로컬 git 인증; 백그라운드 자동갱신엔 `GITHUB_TOKEN`). source=`./경로` 또는 github 객체.
- **업데이트 ✅** — Claude: `claude plugin update ironman` 후 새 세션에서 `/ironman:init`. Codex: `codex plugin marketplace upgrade ironman` + `codex plugin add ironman@ironman` 후 새 세션에서 `/ironman:init`. 이 재-init이 하네스와 전역 daily skills를 동기화한다.
- **비용 ✅ 0원** — Anthropic 수수료·승인 없음.
- **explicit-invocation ✅** — `disable-model-invocation: true`. 플러그인 스킬 표면 `/plugin:skill`.
- **Codex ⚠ 미문서화** — Anthropic 공식문서에 Codex 플러그인 메커니즘 없음. dryforge가 실제 Codex 플러그인을 싣고 있으니(`codex plugin marketplace add` / `codex plugin add`) **dryforge 구조를 정본 예시**로 차용 + Phase F 실설치 검증. self-locating bin이 plugin-root 변수에 비의존이라 위험 최소.

출처: code.claude.com/docs — plugins.md · plugin-marketplaces.md · plugins-reference.md · skills.md.

---

## 참고 자료 (재도출 불필요)

- **dryforge 클론**: `C:\Users\lsc95\AppData\Local\Temp\dryforge-analysis-20260611-101614\dryforge\` — migration 스킬 정본 `src/skills/migration/SKILL.md`(+`references/migration-elicit.md`·`harness-review.md`·`harness-format.md`), 플러그인 구조(`build/build.sh`, `.claude-plugin/marketplace.json`, `claude/`·`codex/plugin/`).
- **bmad-help 정본**: `C:\00_EVERBUILD\bmad-test\.claude\skills\bmad-help\SKILL.md` + 카탈로그 `_bmad\_config\bmad-help.csv`(상태→다음스킬 라우팅·완료감지 패턴).
- **현 시스템 핵심 파일**: `scripts/install-skills.sh`(전역 스킬+Codex shim), `scripts/update-workflow.sh`+`workflow-manifest.txt`(자산 3-way), `scripts/reset-for-new-project.sh`, `scripts/diagnose.sh`+`next-task.sh`(상태엔진), `skills/concept/CONTEXT-FORMAT.md`·`ADR-FORMAT.md`(migration이 인용할 포맷).
- **유저 컴즈**: 승철님 호칭, 정확한 명칭+한 줄 뜻풀이, 질문은 본문 텍스트(팝업 금지).
