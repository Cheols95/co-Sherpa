# agent-commands.md - commands to give coding agents

이 문서는 개발자가 코딩 에이전트에게 상황별로 어떤 검증을 요청하면 되는지 적은 문장 모음이다.

>> 에이전트에게 정확한 명령문을 주면, 사람이 매번 검사 조합을 기억하지 않아도 된다.

## 대표 문장

상황: 빠른 기본 검증이 필요하다.
에이전트에게 말할 문장:
"빠른 검증 해줘. bash dev/release-verification/verify.sh quick를 실행하고 실패만 요약해줘. 아직 코드는 수정하지 마."

상황: 플러그인 패키징을 확인해야 한다.
에이전트에게 말할 문장:
"플러그인 패키징 검증 해줘. bash dev/release-verification/verify.sh plugin을 실행하고, 실패하면 어떤 단계가 실패했는지만 정리해줘."

상황: 배포 전 최종 확인이 필요하다.
에이전트에게 말할 문장:
"배포 전 검증 해줘. bash dev/release-verification/verify.sh release를 실행하고, 실패하면 배포 차단 사유와 dev/release-verification/release-report.md의 핵심 내용을 정리해줘."

상황: full E2E 준비 상태를 보고 싶다.
에이전트에게 말할 문장:
"full E2E 준비 상태를 확인해줘. bash dev/release-verification/verify.sh e2e-preflight를 실행하고, 문제가 없으면 dev/release-verification/cosherpa-e2e-goal.md를 goal로 실행할 준비가 됐는지 알려줘."

## Situation Matrix

| 상황 | 에이전트에게 말할 문장 |
| --- | --- |
| README나 문서만 수정했다 | "bash dev/release-verification/verify.sh quick를 실행하고, 실패 원인만 요약해줘. 소스 코드는 수정하지 마." |
| skill markdown을 수정했다 | "skill 문서 변경 검증해줘. quick profile을 실행하고 markdown 변경 때문에 깨진 static/verifier 항목만 요약해줘." |
| lifecycle skill인 init/help/migration을 수정했다 | "lifecycle skill 변경 검증해줘. static과 quick을 실행하고 init/help/migration source 또는 overlay 누락이 있는지 정리해줘." |
| `cosherpa-init`을 수정했다 | "cosherpa-init 검증해줘. static을 실행해서 entrypoint 권한과 임시 scratch init smoke를 확인하고, 필요하면 plugin profile 결과를 별도로 보고해줘." |
| plugin manifest를 수정했다 | "plugin manifest 검증해줘. static을 실행해서 Claude/Codex manifest JSON parse와 release identity mismatch만 요약해줘." |
| build/package/release script를 수정했다 | "build/release script 검증해줘. static과 unit을 실행하고, 패키징 영향이 있으면 plugin profile도 실행해줘." |
| workflow harness script를 수정했다 | "workflow harness script 검증해줘. static, unit, verifier를 실행하고 self-test 또는 canary 실패만 정리해줘." |
| roadmap/dashboard를 수정했다 | "roadmap 검증해줘. unit profile과 verifier profile을 실행하고 roadmap-selftest 실패 구간을 요약해줘." |
| goal/check script를 수정했다 | "goal/check script 검증해줘. unit과 verifier를 실행해서 check-gate-rigor/red-first canary 결과를 알려줘." |
| Codex/Claude platform parity를 수정했다 | "platform parity 검증해줘. static을 실행해서 manifest identity, lifecycle source, Codex overlay 파일 존재 여부를 확인해줘." |
| 배포 직전 | "배포 전 검증 해줘. release profile을 실행하고 배포 패키지 청결성 audit과 release-report 결과를 같이 정리해줘." |
| 큰 기능 변경 후 full E2E가 필요하다 | "full E2E 준비 상태를 확인한 뒤, dev/release-verification/cosherpa-e2e-goal.md를 Codex goal로 실행할 계획을 세워줘. 먼저 e2e-preflight만 실행해줘." |

>> lifecycle skill은 설치, 도움말, migration처럼 플러그인 생명주기에서 직접 호출되는 표면이다.
