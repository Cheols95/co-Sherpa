# verification-matrix.md - change type to verification profile matrix

이 표는 "이 파일을 고쳤으면 어떤 검사를 돌려야 하는가"를 빠르게 고르기 위한 matrix다.

>> matrix는 변경 유형과 검증 profile을 한눈에 연결해 주는 표다.

| 변경 유형 | 예시 파일 | 최소 검사 | 권장 검사 | 배포 전 필수 검사 | 실패 시 기록 위치 | 에이전트에게 말할 문장 |
| --- | --- | --- | --- | --- | --- | --- |
| README/문서만 수정 | `README.md`, `Workflow_Guideline_v2.html` | `quick` | `quick` | `release` | agent summary 또는 audit report | "문서 변경 quick 검증해줘. 실패 원인만 요약하고 코드는 수정하지 마." |
| skill markdown 수정 | `workflows-coSherpa/skills/*/SKILL.md` | `quick` | `static`, `quick` | `release`, 필요 시 full E2E | audit report defects | "skill markdown 변경 검증해줘. quick을 실행하고 깨진 profile만 알려줘." |
| lifecycle skill 수정: init/help/migration | `workflows-coSherpa/plugin/src/skills/init/SKILL.md` | `static` | `static`, `quick`, `plugin` | `release`, full E2E | audit report skill table | "lifecycle skill 변경 검증해줘. static과 plugin profile 결과를 요약해줘." |
| `cosherpa-init` 수정 | `workflows-coSherpa/plugin/src/bin/cosherpa-init` | `static` | `static`, `plugin` | `release`, full E2E init phase | audit report lifecycle section | "cosherpa-init 변경 검증해줘. 임시 scratch init smoke까지 확인해줘." |
| plugin manifest 수정 | `workflows-coSherpa/plugin/platform/*/plugin.json` | `static` | `static`, `plugin` | `release` | release blocker section | "manifest 검증해줘. JSON parse와 identity mismatch만 정리해줘." |
| build/package script 수정 | `workflows-coSherpa/plugin/build/build.sh` | `static` | `static`, `plugin` | `release` | release blocker section | "build script 검증해줘. static 후 plugin profile을 실행해줘." |
| release-check 수정 | `workflows-coSherpa/plugin/build/release-check.sh` | `static` | `static`, `plugin`, `release` | `release` | release blocker section | "release-check 변경 검증해줘. 실패 단계와 missing command를 분리해줘." |
| workflow harness script 수정 | `workflows-coSherpa/scripts/*.sh` | `static`, `unit` | `quick` | `release` | verifier section | "workflow script 검증해줘. static, unit, verifier를 실행해줘." |
| roadmap/dashboard 수정 | `workflows-coSherpa/dashboard/engines/roadmap.sh` | `unit` | `unit`, `verifier` | `release`, full E2E roadmap phase | roadmap section | "roadmap 검증해줘. roadmap-selftest 결과와 한계를 같이 알려줘." |
| goal/check script 수정 | `check-gate-rigor.sh`, `red-first-check.sh` | `unit` | `unit`, `verifier` | `release` | verifier canary section | "goal check script 검증해줘. canary 실패 여부를 정리해줘." |
| Codex/Claude platform parity 수정 | `workflows-coSherpa/plugin/platform/*` | `static` | `static`, `plugin` | `release` | parity section | "platform parity 검증해줘. manifest와 overlay 파일 존재를 확인해줘." |
| release metadata 수정 | `plugin.json`, `cosherpa-init --version`, `LICENSE` | `static` | `plugin`, `release` | `release` | release blocker section | "release metadata 검증해줘. version과 display identity 불일치를 찾아줘." |
| full E2E 시나리오 수정 | `mini-commerce-ops-scenario.md`, `cosherpa-e2e-goal.md` | `e2e-preflight` | `quick`, `e2e-preflight` | full E2E, `release` | `audit_agent_report.html` | "E2E 준비 상태를 확인해줘. e2e-preflight를 실행하고 goal prompt 실행 준비를 알려줘." |

>> 배포 전 필수 검사는 release 후보에서 반드시 보는 항목이고, 최소 검사는 개발 중 빠르게 확인하는 항목이다.
