# README.md - co-Sherpa release verification package

이 디렉터리는 co-Sherpa 플러그인 개발자 전용 검증 패키지다. 사용자에게 배포되는 플러그인 기능이 아니며, 배포 전이나 큰 변경 후에 개발자가 반복해서 실행할 결정론적 검사 묶음이다.

>> 결정론적 검사는 에이전트의 즉흥 판단이 아니라, 같은 입력이면 같은 exit code와 로그를 내는 스크립트 검사다.

중심 진입점은 `dev/release-verification/verify.sh`다. 문서는 보조 자료이고, 성공/실패 판단의 기준은 가능한 한 이 스크립트의 profile 실행 결과에 둔다.

>> 사람이 매번 명령을 골라 붙여넣는 방식이 아니라, 코딩 에이전트에게 profile 하나를 실행하게 하는 방식이다.

## Profiles

| Profile | 목적 | 실행 예 |
| --- | --- | --- |
| `quick` | 평소 가장 자주 돌리는 빠른 검사 | `bash dev/release-verification/verify.sh quick` |
| `static` | shell syntax, manifest, 경로, 하네스 root 같은 정적 계약 검사 | `bash dev/release-verification/verify.sh static` |
| `unit` | repo에 이미 있는 shell self-test 실행 | `bash dev/release-verification/verify.sh unit` |
| `verifier` | 검증 스크립트가 대표 오류를 잡는지 canary fixture로 확인 | `bash dev/release-verification/verify.sh verifier` |
| `plugin` | plugin build, release smoke, dist 동기화 확인 | `bash dev/release-verification/verify.sh plugin` |
| `release` | 배포 직전 회귀 검사, 패키지 재생성, 패키지 청결성 검사, release report 생성 | `bash dev/release-verification/verify.sh release` |
| `e2e-preflight` | full E2E 실행 전 준비 상태 확인 | `bash dev/release-verification/verify.sh e2e-preflight` |

>> profile은 검사 묶음 이름이다. 빠른 검사와 무거운 배포 검사를 분리해서 평소 반복 비용을 낮춘다.

## Quick vs Release

`quick`은 `git diff --check`, `static`, `unit`, `verifier`를 실행한다. full release check와 full E2E는 실행하지 않는다.

`release`는 `quick` 회귀 검사를 먼저 실행한 뒤 `workflows-coSherpa/plugin/build/build.sh`로 dist를 재생성하고, 배포 패키지 청결성 audit, `workflows-coSherpa/plugin/build/release-check.sh`, dist 동기화 검사를 순서대로 실행한다. 결과는 `dev/release-verification/release-report.md`에 남긴다. 이 profile이 실패하면 배포 차단 후보로 본다.

>> quick은 일상 점검이고, release는 배포 직전 관문이다. 배포 패키지 청결성 audit은 runtime state, E2E 산출물, project PRD/issue/goal 같은 배포 금지 파일이 dist에 섞였는지 보는 검사다.

## Full E2E

full E2E는 자동으로 매번 실행하지 않는다. 배포 후보나 큰 변경 뒤에 `dev/release-verification/cosherpa-e2e-goal.md`를 Codex goal로 실행한다.

먼저 사전 점검을 실행한다.

```bash
bash dev/release-verification/verify.sh e2e-preflight
```

문제가 없으면 `dev/release-verification/cosherpa-e2e-goal.md`를 목표 프롬프트로 넘긴다. full E2E는 repo root 아래 `e2e_shop_demo/` scratch project를 만들 수 있으며, 결과 audit report는 `audit_agent_report.html`에 남긴다.

>> full E2E는 실제 작은 프로젝트를 만들어 co-Sherpa workflow를 끝까지 밟아 보는 무거운 검사다.

## Migration Verification

migration 검증은 실제 외부 프로젝트를 사용하지 않는다. full E2E goal이 임시 migration fixture project를 직접 만들고, 기존 파일이 보존되는지와 `workflows-coSherpa/` 하네스 경로가 쓰이는지 확인한다.

>> 실제 업무 프로젝트를 검증 대상으로 쓰면 파일이 우발적으로 바뀔 수 있으므로, 안전한 가짜 프로젝트를 만든다.

## Before Running

- 현재 branch와 `git status --short`를 확인한다.
- 의도하지 않은 `workflows-coSherpa/plugin/dist` diff가 있는지 확인한다.
- `plugin` 또는 `release` profile은 로컬 Claude/Codex CLI 유무에 영향을 받을 수 있다.
- full E2E 전에는 `e2e-preflight`를 먼저 실행한다.

>> CLI는 command line interface의 줄임말이다. 터미널에서 실행하는 프로그램을 뜻한다.

## Generated Artifacts

검증 중 생길 수 있는 산출물은 다음과 같다.

- `dev/release-verification/release-report.md`: release profile이 덮어쓰는 최신 배포 전 검증 report
- `audit_agent_report.html`: full E2E audit report
- `e2e_shop_demo/`: Mini Commerce Ops scratch project
- `e2e_shop_demo_YYYYMMDD_HHMMSS/`: 기존 scratch project가 있을 때 쓰는 timestamp 대체 경로
- `e2e_migration_fixture/` 또는 timestamp 대체 경로: migration 검증 fixture
- `workflows-coSherpa/plugin/dist/`: `plugin` 또는 `release` profile에서 build가 재생성할 수 있는 dist 산출물

>> artifact는 검사나 빌드가 남기는 결과 파일 또는 폴더다.

## Failure Handling

검증 실패는 먼저 로그와 audit report에 기록한다. source defect가 플러그인 쪽 문제로 보이면 이 검증 goal 안에서 즉시 고치지 않고 결함으로 남긴다. 단, `dev/release-verification/` 아래 검증 패키지 자체의 결함은 이 goal 범위 안에서 수정할 수 있다.

실패 원인별로 볼 문서는 다음과 같다.

- profile 선택 기준: `verification-policy.md`
- 변경 유형별 검사 선택: `verification-matrix.md`
- 검증 스크립트 신뢰 범위: `verifier-contract.md`
- 사람이 점검할 항목: `checklist.md`
- 에이전트에게 말할 문장: `agent-commands.md`

>> source defect는 제품 코드나 플러그인 기능 자체의 결함이다. 검증 도구 결함과 구분해서 기록한다.

## Cleanup Before Release

배포 전에는 scratch project, migration fixture, audit report 초안, 의도하지 않은 dist diff를 정리하거나 보존 결정을 기록한다. `release` profile은 배포되는 dist를 다시 만들고 배포 금지 산출물이 섞였는지 검사하지만, 사용자가 만든 기존 root-level report나 scratch folder를 임의 삭제하지 않는다. `verification-matrix.md`와 `checklist.md`를 함께 확인한다.

>> 정리는 단순 삭제가 아니라, 보존할 증거와 제거할 임시 파일을 구분하는 작업이다.
