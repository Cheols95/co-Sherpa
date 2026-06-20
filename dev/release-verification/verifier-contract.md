# verifier-contract.md - verification script trust contract

이 문서는 기존 검증 스크립트가 무엇을 보장하고 무엇을 보장하지 않는지 정의한다. `verify.sh`는 이 한계를 보완하기 위해 self-test와 canary fixture를 함께 실행한다.

>> canary fixture는 일부러 틀린 입력을 넣어 검사가 실제로 실패하는지 확인하는 작은 테스트용 프로젝트다.

## Script Contract Table

| 스크립트 | 목적 | 잡을 수 있는 오류 | 잡지 못하는 오류 | 이 패키지의 보완 | 실패 시 해석 |
| --- | --- | --- | --- | --- | --- |
| `workflows-coSherpa/plugin/build/build.sh` | Claude/Codex plugin dist 재생성 | 누락된 source 파일, 복사 실패, packaging script 오류 | 스킬 응답의 의미적 정확성, 사용자 workflow 품질 | `plugin`/`release` profile에서 build 후 dist 멱등성 + `git status --porcelain` 동기화 확인, full E2E에서 사용자 흐름 확인 | package source와 dist 생성 경로를 먼저 본다 |
| `workflows-coSherpa/plugin/build/release-check.sh` | release smoke aggregator | dist 재생성 문제, 실행 권한, LF, host validator, install smoke, scratch init, template clean, metadata mismatch | 모든 daily skill 의미 정확성, 장기 workflow 회귀 | `release` profile에서 배포 직전 실행, full E2E에서 13개 사용자 표면 검증 | 실패는 배포 차단 후보로 기록한다 |
| `workflows-coSherpa/dashboard/engines/roadmap-selftest.sh` | roadmap DATA contract와 embedded JS syntax 검사 | dependency parsing, ready count, active/green shading, service-flow DATA, embedded JS syntax | 실제 브라우저 픽셀 렌더링, 시각적 겹침, 사용성 | `unit`과 `verifier`에서 실행하고, full E2E에서 dashboard 파일 생성 확인 | DATA 생성 또는 dashboard script contract 회귀로 본다 |
| `workflows-coSherpa/scripts/check-gate-rigor.sh` | universal claim에 반복 gate가 있는지 확인 | "every/all/each" 같은 보편 주장에 좁은 gate가 붙는 문제 | 반복문이 올바른 source-of-truth를 순회하는지, assertion 품질 | `verifier` canary가 universal claim + 비반복 gate 실패와 반복 gate 통과를 확인 | gate 설계가 goal 주장 범위를 못 따라간다는 신호다 |
| `workflows-coSherpa/scripts/red-first-check.sh` | `/build` 변환 직후 gate가 구현 전 red인지 확인 | pre-implementation green gate, tautology gate | 이미 구현된 steady state 회귀, broken wiring의 hard fail 판정 | `verifier` canary가 `exit 0` tautology 실패와 `exit 1` assertion-red 통과를 확인 | 변환 직후 gate가 teeth를 갖는지 해석한다 |
| `workflows-coSherpa/scripts/template-clean-check.sh` | 배포 템플릿에 프로젝트별 찌꺼기가 남았는지 확인 | PRD/issue/concept/goal/runtime state leftover, dashboard artifact 누락 | runtime correctness, plugin semantic correctness | `verifier` canary가 dirty fixture를 주입해 실패하는지 확인 | 템플릿 정리 또는 release surface 정리가 필요하다 |

>> semantic validator는 기능의 의미가 맞는지 보는 검사다. `build.sh`는 파일을 만드는 generator이지 의미 검증기가 아니다.

## Required Limitations

- `build.sh`는 packaging generator이지 semantic validator가 아니다. 산출물을 만들 수는 있지만, 스킬이 실제 사용자 흐름에서 좋은 답을 하는지는 보장하지 않는다.
- `release-check.sh`는 release smoke aggregator다. plugin dist, manifest, 설치 smoke, scratch init은 보지만 모든 daily skill의 의미적 정확성은 full E2E가 봐야 한다.
- `roadmap-selftest.sh`는 DATA contract와 embedded JS syntax를 확인하지만, 실제 브라우저 픽셀 렌더링까지 보장하지 않는다.
- `check-gate-rigor.sh`는 universal claim에 반복 gate가 있는지 보는 heuristic이다. 반복문이 올바른 source-of-truth를 순회하는지는 별도 gate 또는 review가 봐야 한다.
- `red-first-check.sh`는 conversion-time 검사다. goal이 이미 구현된 뒤에는 green이 정상일 수 있으므로 steady-state 회귀 검사로 쓰면 안 된다.
- `red-first-check.sh`의 broken wiring은 현재 warning 성격일 수 있다. 따라서 release-level 검증에서는 실제 gate green까지 확인해야 한다.
- `template-clean-check.sh`는 배포 템플릿에 프로젝트별 찌꺼기가 남았는지 보는 검사다. runtime correctness를 보장하지 않는다.

>> heuristic은 완벽한 증명이 아니라 강한 신호를 주는 규칙이다. 통과해도 review가 필요할 수 있다.

## Verifier Profile Negative Controls

`verifier` profile은 다음 대표 negative control을 실행한다.

| Canary | Negative control | Positive control | Known gap |
| --- | --- | --- | --- |
| `check-gate-rigor` | universal claim이 있는데 `.gates.sh`에 반복이 없으면 실패해야 한다 | 같은 fixture에 `for` 반복을 넣으면 통과해야 한다 | 반복 대상이 진짜 source-of-truth인지는 보장하지 않는다 |
| `red-first-check` | 구현 전 `exit 0` gate는 실패해야 한다 | 구현 전 `exit 1` assertion gate는 통과해야 한다 | broken wiring은 warning 후 exit 0일 수 있다 |
| `template-clean-check` | PRD/issue leftover가 있는 fixture는 실패해야 한다 | 별도 clean positive fixture는 현재 자동화하지 않는다 | dirty detection 중심 canary이며 runtime correctness는 보장하지 않는다 |
| `roadmap-selftest` | built-in fixture self-test를 실행한다 | dependency, ready, shading, service, render group이 통과해야 한다 | headless browser pixel render는 보장하지 않는다 |

>> negative control은 일부러 고장난 입력이다. 고장난 입력에서 실패하지 않는 검사는 믿기 어렵다.
