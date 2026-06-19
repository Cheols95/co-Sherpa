# cosherpa-e2e-goal.md - full E2E goal prompt for co-Sherpa release candidates

목표: co-Sherpa 플러그인이 실제 사용자 workflow에서 작동하는지 full E2E로 검증하라.

이 goal은 개발자용 검증 실행이다. 플러그인을 외부 사용자에게 배포하지 않는다. plugin source 결함을 발견하면 즉시 수정하지 말고 `audit_agent_report.html`에 기록한다.

>> full E2E는 사용자가 플러그인을 설치해서 실제 작은 프로젝트를 만드는 흐름을 끝까지 따라가는 검증이다.

## 검증 대상

- plugin lifecycle surface
- daily workflow skills
- scratch project init
- concept to freeze to build flow
- finding/cycle/spec-sync/architecture/roadmap/handoff support flow
- release-check 전후 회귀

>> lifecycle surface는 `/cosherpa:init`, `/cosherpa:help`, `/cosherpa:migration`처럼 설치와 온보딩에 직접 닿는 명령 표면이다.

## 실행 전제

- 쇼핑몰 scratch 프로젝트는 repo root의 `e2e_shop_demo/`에 생성한다.
- E2E 시작 전에 `e2e_shop_demo/`를 미리 만들 필요는 없다.
- `e2e_shop_demo/`가 없으면 full E2E goal이 생성한다.
- `e2e_shop_demo/`가 비어 있으면 그대로 사용한다.
- `e2e_shop_demo/`가 비어 있지 않으면 삭제하지 말고 기존 산출물로 기록한 뒤 timestamp suffix를 붙인 별도 scratch folder를 사용할지 결정한다.
- full E2E 시작 시 실제 사용할 scratch project 경로를 `SCRATCH_DIR`로 확정한다.
- 기본 `SCRATCH_DIR`는 `e2e_shop_demo/`다.
- timestamp suffix 폴더를 선택하면 이후 모든 init, concept, freeze, build, roadmap, handoff, audit 경로는 그 `SCRATCH_DIR`를 기준으로 쓴다.
- scratch project scenario는 `Mini Commerce Ops`다.
- scenario 정의는 `dev/release-verification/mini-commerce-ops-scenario.md`를 따른다.
- audit 보고서는 repo root의 `audit_agent_report.html`에 생성한다.
- roadmap 대시보드는 `$SCRATCH_DIR/workflows-coSherpa/dashboard/roadmap.html`에 생성한다.
- `/cosherpa:init`은 `$SCRATCH_DIR`에서 검증한다.
- `/cosherpa:migration`은 외부 실제 프로젝트가 아니라 E2E 중 생성한 임시 migration fixture project에서 검증한다.
- 나머지 사용자 표면 스킬은 확정된 `$SCRATCH_DIR` 개발 흐름에서 최소 1회씩 사용한다.
- 시작 전과 종료 후 `bash workflows-coSherpa/plugin/build/release-check.sh`를 실행한다.

>> `SCRATCH_DIR`는 이번 E2E에서 실제로 작업할 가짜 프로젝트 폴더를 가리키는 변수 이름이다.

## 외부 실제 프로젝트 사용 금지

`/cosherpa:migration` 검증에 실제 외부 프로젝트를 사용하지 않는다. E2E goal 안에서 안전한 임시 migration fixture directory를 직접 생성한다.

권장 경로:

```text
e2e_migration_fixture/
```

이미 같은 경로가 있으면 지우지 말고 `e2e_migration_fixture_YYYYMMDD_HHMMSS/`처럼 새 경로를 만든다. audit report에 실제 경로를 기록한다.

>> 실제 작업 프로젝트를 테스트 대상으로 쓰면 우발적으로 파일이 바뀔 수 있다. 그래서 검증용 가짜 프로젝트를 새로 만든다.

## Migration Fixture Project

fixture project는 "기존 프로젝트에 co-Sherpa를 도입하는 상황"을 흉내 낸다.

필수 파일:

```text
e2e_migration_fixture/README.md
e2e_migration_fixture/package.json
e2e_migration_fixture/src/app.js
e2e_migration_fixture/docs/notes.md
```

요구사항:

- 작은 JavaScript utility app처럼 보이게 만든다.
- 이미 README가 존재해야 한다.
- 이미 source file이 존재해야 한다.
- 아직 `AGENTS.md`, `CONTEXT.md`, `workflows-coSherpa/`는 없어야 한다.
- migration 후 기존 파일이 삭제되거나 불필요하게 훼손되지 않아야 한다.
- `/cosherpa:migration`이 기존 프로젝트 분석 흐름을 안내하는지 확인한다.
- `AGENTS.md` 또는 `CONTEXT.md`가 생성/갱신되는 경우 기존 프로젝트 맥락을 반영하는지 확인한다.
- 구형 하네스 디렉터리가 생성되지 않는지 확인한다.

>> migration fixture는 이미 존재하는 프로젝트에 co-Sherpa를 붙이면 어떤 일이 생기는가를 안전하게 검증하는 가짜 프로젝트다.

## 대상 스킬

full E2E에서 다음 13개 사용자 표면을 최소 1회씩 검증한다.

```text
/cosherpa:init
/cosherpa:help
/cosherpa:migration
/concept
/freeze
/build
/finding
/cycle
/roadmap
/prototype
/spec-sync
/improve-codebase-architecture
/handoff
```

각 스킬별로 audit report에 다음을 기록한다.

- 입력
- 기대 결과
- 실제 결과
- 생성/수정된 주요 파일
- 정상 여부
- 결함 또는 의심점

>> 사용자 표면은 사람이 실제로 호출하는 명령이나 skill 진입점이다.

## Test Agent와 Review Agent

가능하면 multi-agent 도구를 사용한다.

- Test Agent: co-Sherpa 사용자가 되어 `Mini Commerce Ops`를 개발한다.
- Review Agent: 각 스킬이 의도대로 작동했는지 검토하고 전체 과정을 `audit_agent_report.html`에 기록한다.

제약:

- Test Agent는 scratch project 구현 파일을 확정된 `$SCRATCH_DIR` 안에서만 수정한다.
- Review Agent는 plugin source를 수정하지 않는다.
- 플러그인 source 결함을 발견하면 수정하지 말고 audit report에 기록한다.
- multi-agent 도구가 없으면 main agent가 두 역할을 순차적으로 수행하고 audit report에 "single-agent fallback"이라고 기록한다.

>> Test Agent는 실제 사용자 역할이고, Review Agent는 검사관 역할이다.

## Phase 1. Baseline release check

repo root에서 실행한다.

```bash
bash workflows-coSherpa/plugin/build/release-check.sh
```

결과를 audit report에 기록한다. 실패하면 full E2E를 계속할지 중단할지 판단하고, plugin source를 자동 수정하지 않는다. 실패 로그를 audit report의 "배포 차단 후보"에 기록한다.

## Phase 2. Scratch project setup

repo root에 `e2e_shop_demo/`를 만든다. 이미 존재하면 지우지 않는다. 비어 있으면 그대로 사용하고, 비어 있지 않으면 기존 산출물로 audit report에 기록한 뒤 timestamp suffix folder 사용 여부를 결정한다.

확정된 `$SCRATCH_DIR`에서 `/cosherpa:init`을 검증한다.

확인할 것:

- `AGENTS.md` 생성 여부
- `CONTEXT.md` 생성 여부
- `workflows-coSherpa/` 생성 여부
- 구형 하네스 디렉터리 미생성 여부
- daily skills 안내가 정상인지

## Phase 3. Help surface

`/cosherpa:help`를 호출하거나 해당 plugin help skill이 안내하는 내용을 확인한다.

확인할 것:

- lifecycle commands 안내
- daily workflow commands 안내
- init/update/migration 안내
- Claude와 Codex 사용 표면이 혼동 없이 설명되는지

## Phase 4. Migration fixture setup and migration test

repo root에 migration fixture project를 생성한다. 권장 경로는 `e2e_migration_fixture/`이며 이미 존재하면 timestamp suffix를 붙인다.

fixture 생성 후 `/cosherpa:migration`을 그 fixture project에서 검증한다.

확인할 것:

- 기존 README/source 보존
- 기존 프로젝트 맥락 분석
- `AGENTS.md`/`CONTEXT.md` 생성 또는 갱신의 적절성
- `workflows-coSherpa/` 경로 사용
- 구형 하네스 디렉터리 미생성
- migration 안내가 실제 프로젝트 온보딩에 충분한지

## Phase 5. Concept

확정된 `$SCRATCH_DIR`에서 `/concept`를 사용해 Mini Commerce Ops 기능 개념을 닫는다.

의도적으로 다룰 결정거리:

- 재고 차감 시점: cart add 시점인지 checkout 시점인지
- checkout 실패 조건: 재고 부족, 빈 cart, 비로그인
- 주문 최초 상태: `paid`
- 주문 상태 전이: `paid -> preparing -> shipped`
- role policy: customer와 admin 권한
- coupon policy: `SHERPA10` 1회 적용 범위
- 데이터 저장 방식: 브라우저 메모리 또는 local state
- 정적 앱에서 payment를 simulated payment로 처리하는 방식

확인할 것:

- `workflows-coSherpa/docs/concept/checklist.md`가 decision surface를 닫는 데 쓰였는지
- `CONTEXT.md`에 용어가 정리됐는지
- ADR 또는 rationale이 필요한 결정이 기록됐는지

## Phase 6. Freeze

`/freeze`를 실행해 닫힌 concept를 계약으로 봉인한다.

확인할 것:

- PRD 생성 여부
- spec 생성 여부
- issue 생성 여부
- graph-lint 또는 issue dependency 검증 통과 여부
- freeze 이후 결정이 흔들리지 않도록 문서가 정리됐는지

## Phase 7. Build

`/build`를 실행해 최소 2개 이상의 vertical slice를 goal 계약으로 변환하고 구현한다.

최소 구현 slice 예시:

- Slice 1: catalog + cart + stock guard
- Slice 2: checkout + order creation + stock decrement
- 선택 Slice 3: admin order status transition
- 선택 Slice 4: coupon application

확인할 것:

- `workflows-coSherpa/goals/<n>-*.md`
- `workflows-coSherpa/goals/<n>-*.gates.sh`
- `workflows-coSherpa/goals/<n>-*.next-task.sh`
- goal gate red-first evidence
- `bash workflows-coSherpa/scripts/completion-check.sh` 또는 goal gate 통과 여부
- 구현 파일이 확정된 `$SCRATCH_DIR` 안에만 있는지

## Phase 8. Finding

`/finding`을 사용해 범위 밖 개선점 1개 이상을 기록한다.

예시:

- browser state reset UX 개선
- order filtering 개선
- accessibility 개선
- richer test harness 추가

확인할 것:

- `workflows-coSherpa/docs/findings/`에 finding이 기록됐는지
- 현재 goal 범위 밖이라는 설명이 있는지

## Phase 9. Cycle

`/cycle`을 사용해 finding을 묶어 cycle 문서를 만든다.

확인할 것:

- `workflows-coSherpa/cycles/`에 cycle 문서가 생성됐는지
- cycle 문서가 한 세션에서 실행 가능한 loop-driver인지
- 실행 또는 다음 작업 지시가 명확한지

## Phase 10. Spec-sync drift check

의도적 drift를 1개 만든 뒤 `/spec-sync`를 실행한다.

drift 예시:

- spec에는 coupon code가 `SHERPA10`인데 UI label에 다른 표현을 추가한다.
- spec에는 order status 순서가 고정돼 있는데 code comment 또는 doc에 모호한 표현을 둔다.
- 사용자에게 보이는 기능을 심각하게 망가뜨리는 drift는 만들지 않는다.

확인할 것:

- `/spec-sync`가 spec/code/doc drift를 식별하는지
- 문서만 고치면 되는 것은 정리하는지
- 코드 수정이 필요한 것은 finding으로 큐잉하는지
- drift를 만든 후 최종 상태를 다시 일관되게 정리하는지

## Phase 11. Architecture review

`/improve-codebase-architecture`를 사용해 cart/checkout/orders 모듈 경계를 검토한다.

확인할 것:

- cart state와 checkout rules의 결합도
- order transition logic의 위치
- 테스트 가능한 경계
- architecture review 산출물이 생성되는지
- plugin source가 아니라 scratch project만 대상으로 검토하는지

## Phase 12. Roadmap

`/roadmap`을 실행해 roadmap dashboard를 생성한다.

확인할 것:

```text
$SCRATCH_DIR/workflows-coSherpa/dashboard/roadmap.html
```

추가 확인:

```bash
bash "$SCRATCH_DIR/workflows-coSherpa/dashboard/engines/roadmap-selftest.sh"
```

dashboard HTML이 생성되고 self-test가 통과했는지 audit report에 기록한다.

## Phase 13. Prototype

`/prototype`을 최소 1회 사용한다.

적합한 prototype 주제:

- admin order board UI variant
- cart/checkout state machine terminal prototype
- coupon policy interaction prototype

확인할 것:

- prototype이 production code와 구분되는지
- prototype 결과가 바로 제품 코드로 섞이지 않는지
- prototype에서 얻은 결정 또는 finding이 기록되는지

## Phase 14. Handoff

`/handoff`를 실행해 최종 상태 요약을 생성한다.

확인할 것:

- 생성 위치
- 다음 agent가 이어받을 수 있는 상태 설명
- 통과한 gate와 남은 결함
- E2E 산출물 목록

## Phase 15. Final release check

repo root로 돌아와 다시 실행한다.

```bash
bash workflows-coSherpa/plugin/build/release-check.sh
```

확인할 것:

- 시작 전 release-check 결과와 종료 후 release-check 결과 비교
- E2E 과정이 plugin release surface를 망가뜨리지 않았는지
- 최종 판정: PASS / CONDITIONAL PASS / FAIL

## Mini Commerce Ops 기능 acceptance

E2E가 끝날 때 앱은 최소 다음 동작을 만족해야 한다.

- 더미 상품 3개가 표시된다.
- 각 상품의 재고가 표시된다.
- 품절 상품은 장바구니에 추가할 수 없다.
- 재고보다 많은 수량을 장바구니에 담을 수 없다.
- `customer@example.com`으로 customer login이 된다.
- `admin@example.com`으로 admin login이 된다.
- 알 수 없는 이메일은 login 실패 상태를 보여준다.
- customer는 cart add/remove/qty change를 할 수 있다.
- customer는 `SHERPA10` 쿠폰을 checkout당 한 번 적용할 수 있다.
- checkout은 simulated payment로 처리된다.
- checkout 성공 시 order가 생성된다.
- checkout 성공 시 order 최초 상태는 `paid`다.
- checkout 성공 시 재고가 차감된다.
- checkout 성공 시 cart가 비워진다.
- admin은 주문 목록을 볼 수 있다.
- admin은 주문 상태를 `paid -> preparing -> shipped` 순서로 변경할 수 있다.
- admin은 상태를 건너뛸 수 없다.
- customer는 admin 상태 변경 UI를 사용할 수 없다.

## E2E Audit Report Requirements

full E2E 종료 시 repo root의 다음 파일을 생성 또는 갱신한다.

```text
audit_agent_report.html
```

템플릿은 `dev/release-verification/audit_agent_report.template.html`를 기준으로 한다. audit report는 한국어로 작성한다.

반드시 포함할 항목:

- 검증 개요
- 환경 정보
- 사용한 commit SHA
- plugin id: `cosherpa`
- display name: `co-Sherpa`
- scratch scenario: `Mini Commerce Ops`
- scratch project path
- migration fixture path
- 하네스 경로: `workflows-coSherpa/`
- 시작 전 release-check 결과
- 종료 후 release-check 결과
- 각 스킬별 입력 / 기대 결과 / 실제 결과 / 정상 여부
- Test Agent 작업 로그
- Review Agent 검토 로그
- Mini Commerce Ops 최종 산출물 링크
- roadmap 대시보드 링크
- migration fixture 검증 결과
- 발견된 결함
- 배포 전 정리 대상
- 최종 판정: PASS / CONDITIONAL PASS / FAIL

## E2E Failure Handling

E2E 중 실패가 발생하면:

- plugin source를 즉시 수정하지 않는다.
- 실패한 phase와 command를 audit report에 기록한다.
- scratch project 내부 구현 문제라면 확정된 `$SCRATCH_DIR` 안에서만 수정할 수 있다.
- plugin source 결함으로 보이면 audit report의 "발견된 결함"에 기록한다.
- 검증을 계속할 수 있으면 계속하고, 계속할 수 없으면 blocked 상태와 이유를 기록한다.

>> full E2E의 목적은 plugin source를 몰래 고치는 것이 아니라, 배포 전 신뢰할 수 있는 증거를 남기는 것이다.
