# verification-policy.md - verification profile selection policy

이 문서는 co-Sherpa 개발자가 변경 유형과 위험도에 따라 어떤 `verify.sh` profile을 실행할지 정하는 정책이다.

>> 정책은 “이럴 때는 이 검사를 돌린다”는 약속이다. 검사 선택을 사람 기분에 맡기지 않기 위한 문서다.

## Profile Selection

`quick`은 평소 가장 자주 실행하는 빠른 검사다. README, 일반 문서, skill markdown, 작은 shell script 수정 후 기본으로 실행한다. full release check와 full E2E는 포함하지 않는다.

>> 빠른 검사는 자주 돌릴 수 있어야 가치가 있다.

`static`은 파일명, 경로, shell syntax, manifest metadata, 하네스 root, lifecycle source 누락이 의심될 때 실행한다. read-only 검사를 기본으로 하며, scratch smoke는 임시 디렉터리에서만 수행한다.

>> 정적 검사는 프로그램을 깊게 실행하기보다 구조가 맞는지 확인하는 검사다.

`unit`은 repo에 이미 있는 self-test가 깨졌는지 확인한다. roadmap, gate rigor, red-first self-test가 여기에 들어간다.

>> self-test는 검증 스크립트가 자기 기본 규칙을 아직 만족하는지 보는 작은 테스트다.

`verifier`는 검증 스크립트 자체가 대표 오류를 잡는지 canary fixture로 확인한다. 정상 케이스만 통과하는지 보지 않고, 일부러 깨진 입력에서 실패하는지도 본다.

>> canary fixture는 검사가 진짜 이를 가지고 있는지 확인하는 일부러 고장난 입력이다.

`plugin`은 플러그인 패키징 관련 변경 후 실행한다. `build.sh`, `release-check.sh`, dist 멱등성 검사, dist 동기화 검사(build 후 `git status --porcelain -- workflows-coSherpa/plugin/dist`)를 포함한다. 동기화 검사가 비어있지 않으면(커밋된 dist가 빌드 결과와 다르면) 실패로 처리한다. git work tree가 아니면 SKIP으로 남긴다.

>> dist는 배포 산출물이다. source와 다르면 “갱신 필요”인지 “잘못된 변경”인지 사람이 봐야 한다.

`release`는 배포 직전 반드시 실행한다. `quick` 회귀 검사, dist 재생성, 배포 패키지 청결성 audit, `release-check.sh`, dist 멱등성 검사, dist 동기화 검사(`git status --porcelain`)를 묶어서 실행하고 `dev/release-verification/release-report.md`에 최신 결과를 덮어쓴다. 실패하면 배포 차단 후보로 기록한다.

>> release profile은 최종 smoke test와 package clean audit을 함께 묶은 배포 후보 검사다. smoke test는 큰 문제를 빠르게 드러내는 검사이고, package clean audit은 배포 산출물에 임시 파일이 섞였는지 보는 검사다.

`e2e-preflight`는 full E2E 전 준비 상태를 확인한다. 필요한 goal prompt, scenario, audit template, scratch target 상태를 보지만 full E2E 자체는 실행하지 않는다.

>> preflight는 비행 전 점검처럼, 무거운 실행 전에 준비물이 맞는지 보는 단계다.

## Full E2E Policy

full E2E는 무겁기 때문에 매번 실행하지 않는다. 배포 후보, lifecycle skill 변경, `/concept`부터 `/build`까지의 흐름에 영향을 줄 수 있는 큰 변경 후에 `dev/release-verification/cosherpa-e2e-goal.md`를 Codex goal로 실행한다.

full E2E는 `Mini Commerce Ops` scratch project와 임시 migration fixture를 사용한다. 실제 외부 프로젝트를 migration 검증 대상으로 쓰지 않는다.

>> full E2E는 작은 실제 프로젝트를 만들어 전체 workflow가 작동하는지 보는 검사다.

## Defect Handling

검증 중 source defect를 발견하면 즉시 플러그인 source를 고치지 않고 audit report나 agent report에 먼저 기록한다. 결함의 위치, 재현 명령, 기대 결과, 실제 결과를 남긴다.

단, 이 goal에서 생성한 `dev/release-verification/` 파일의 결함은 바로 수정해도 된다. 이 검증 패키지 자체가 현재 작업 범위이기 때문이다.

>> source defect는 제품이나 플러그인 원본의 문제이고, verification defect는 이 검증 패키지의 문제다.

## Exit Code Policy

`verify.sh`는 전체 성공 시 exit `0`, 검사 실패 시 exit `1`, 알 수 없는 profile 같은 사용법 오류 시 exit `2`를 반환한다. `[SKIP]`은 자동 성공으로 숨기지 않고 로그에 남긴다.

>> exit code는 터미널 명령의 성공/실패를 숫자로 알려주는 결과값이다.

## Release Cleanup Policy

`release` profile은 배포 패키지를 깨끗하게 만들기 위해 `workflows-coSherpa/plugin/dist`를 source에서 다시 생성한다. 그 뒤 dist 안에 runtime state, 검증 report, E2E scratch artifact, project PRD/issue/concept/goal/spec/ADR/finding/cycle artifact, 구형 하네스 디렉터리가 없는지 검사한다.

기존 root-level `audit_agent_report.html`, `e2e_shop_demo/`, `e2e_migration_fixture/` 같은 사람의 검증 증거는 자동 삭제하지 않는다. release profile이 새로 남기는 report는 `dev/release-verification/release-report.md` 하나다.

>> 자동 삭제는 증거를 잃게 만들 수 있다. 그래서 배포 패키지 안은 엄격히 청소하고, repo root의 기존 검증 산출물은 사람이 결정하게 둔다.
