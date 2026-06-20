# checklist.md - manual release verification checklist

이 체크리스트는 자동 검사와 사람이 보는 최종 확인을 연결한다. 각 항목은 실행일, 명령, 결과, 비고를 함께 남긴다.

>> 자동 스크립트가 놓칠 수 있는 판단을 사람이 마지막으로 확인하는 문서다.

## 시작 전 상태

- [ ] 현재 branch 확인
- [ ] `git status --short` 확인
- [ ] remote URL 기록. 단, release policy가 명시하지 않는 한 remote URL 자체를 기본 실패 조건으로 삼지 않는다.
- [ ] 의도한 변경 범위와 금지 수정 경로 확인
- [ ] 기존 `audit_agent_report.html` 존재 여부 확인

## Static checks

- [ ] `bash -n dev/release-verification/verify.sh` 통과
- [ ] `bash dev/release-verification/verify.sh static` 통과
- [ ] manifest JSON parse 확인
- [ ] lifecycle source `init`, `help`, `migration` 확인
- [ ] scratch/migration fixture에서 `workflows-coSherpa/` 생성 확인
- [ ] 구형 하네스 디렉터리 미생성 확인

## Unit checks

- [ ] `bash dev/release-verification/verify.sh unit` 통과
- [ ] `bash workflows-coSherpa/dashboard/engines/roadmap-selftest.sh` 통과
- [ ] `bash workflows-coSherpa/scripts/check-gate-rigor.sh --self-test` 통과
- [ ] `bash workflows-coSherpa/scripts/red-first-check.sh --self-test` 통과

## Verifier canary checks

- [ ] `bash dev/release-verification/verify.sh verifier` 통과
- [ ] `template-clean-check` dirty fixture 실패 확인
- [ ] `check-gate-rigor` universal claim negative control 확인
- [ ] `red-first-check` tautology negative control 확인
- [ ] known gap 기록 확인

## Plugin checks

- [ ] `bash dev/release-verification/verify.sh plugin` 통과
- [ ] plugin profile의 dist tracked-clean 검사 통과 (build 후 `git status --porcelain -- workflows-coSherpa/plugin/dist`가 비어있음 = 커밋된 dist 최신). 실패하면 dist 재생성 후 커밋
- [ ] CLI 누락이면 missing command와 local 환경 조건 기록

## Integration / smoke checks

- [ ] scratch init smoke 결과 확인
- [ ] install smoke 결과 확인
- [ ] template clean 결과 확인
- [ ] release metadata audit 결과 확인

## E2E preflight

- [ ] `bash dev/release-verification/verify.sh e2e-preflight` 통과
- [ ] `dev/release-verification/cosherpa-e2e-goal.md` 존재
- [ ] `dev/release-verification/mini-commerce-ops-scenario.md` 존재
- [ ] `dev/release-verification/audit_agent_report.template.html` 존재
- [ ] `e2e_shop_demo/` 덮어쓰기/보존/timestamp 경로 결정

## Full E2E checks

- [ ] full E2E 실행 여부 기록
- [ ] scratch project에 `workflows-coSherpa/` 생성 확인
- [ ] 구형 하네스 디렉터리 미생성 확인
- [ ] 13개 사용자 표면 스킬 사용 여부 확인
- [ ] Mini Commerce Ops 필수 기능 구현 여부 확인
- [ ] 도메인 규칙 구현 여부 확인
- [ ] roadmap 생성 여부 확인
- [ ] migration fixture 검증 여부 확인

## Release checks

- [ ] `bash dev/release-verification/verify.sh release` 통과
- [ ] `dev/release-verification/release-report.md` 생성 또는 갱신 확인
- [ ] release profile 안에서 `quick` 회귀 검사 통과 확인
- [ ] release package cleanliness audit 통과 확인
- [ ] `bash workflows-coSherpa/plugin/build/release-check.sh` 직접 결과 기록
- [ ] 시작 전 release-check와 종료 후 release-check 비교
- [ ] 실패 시 배포 차단 사유 기록

## 산출물 확인

- [ ] `audit_agent_report.html` 생성 또는 갱신
- [ ] Mini Commerce Ops 최종 산출물 링크 기록
- [ ] roadmap dashboard 링크 기록
- [ ] migration fixture path 기록
- [ ] Test Agent / Review Agent 작업 로그 기록

## 배포 전 정리 대상

- [ ] `e2e_shop_demo/` 또는 timestamp scratch folder 처리
- [ ] `e2e_migration_fixture/` 또는 timestamp fixture 처리
- [ ] 임시 audit report 초안 처리
- [ ] 의도하지 않은 dist diff 처리
- [ ] 로컬 runtime state 처리

## 최종 판정

- [ ] PASS
- [ ] CONDITIONAL PASS
- [ ] FAIL
- [ ] 조건부 통과라면 남은 조건과 책임자 기록

>> CONDITIONAL PASS는 배포 가능하지만 명시된 조건을 나중에 반드시 처리해야 하는 상태다.
