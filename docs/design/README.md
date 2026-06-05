# docs/design/ — 비계약 설계 문서

계약은 아니지만 구현에 필요한 **설계 산출물**을 둔다. `docs/spec/`(계약)와 달리 **권위가 없다** —
PRD/ADR을 override하지 않고, 변동이 잦다. 구현은 참고하되 충돌 시 `docs/spec/`가 이긴다.

| 문서 | 담는 것 |
|---|---|
| `flow.md` | 사용 흐름·유스케이스·상태머신·시퀀스 |
| `screens.md` | 화면/UI 설계, 와이어프레임 |
| `architecture.md` | 코드 모듈 경계·의존 방향 (결정 자체는 `docs/adr/`) |

- **생성:** `/to-spec`이 계약을 추출할 때 비계약 내용을 여기로 분류한다. 직접 작성도 가능.
- **아키텍처 발굴:** `/improve-codebase-architecture`(CONTEXT 도메인어 + ADR 기반).
- 안정 인터페이스(스키마·API·공개 타입)는 여기가 아니라 `docs/spec/`.
- 주의: 여기 `architecture.md`는 **코드 내부 구조**(모듈·의존)다. 로드맵 대시보드가 파싱하는 **서비스 운영 토폴로지**(배포 흐름)는 계약이라 `docs/spec/service-flow.md`에 둔다 — 이름이 비슷하니 혼동 말 것.
