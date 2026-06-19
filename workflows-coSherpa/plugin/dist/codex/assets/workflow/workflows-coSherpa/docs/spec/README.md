# workflows-coSherpa/docs/spec/ — 계약 스펙 (단일 진실원천)

구현이 **PRD·ADR보다 우선해서** 따르는 계약문서를 둔다. `INDEX.md`가 현재 유효한 계약 목록이다.

- **생성:** `/to-spec` — Phase 1→2 경계에서 accepted ADR + PRD를 계약문서로 굳혀 처음 만든다.
- **유지:** `/spec-sync` — 코드·최신 ADR과의 드리프트를 정합(문서만 고치면 직접, 코드 고쳐야 하면 finding).
- **권위·읽기순서:** `AGENTS.md`의 §Spec authority.

여기 들어가는 것 = **안정 인터페이스**: `data-schema.md`, `api-contract.md`, `domain-types.md`,
(이벤트 기반이면) `events.md`, (필요시) `config.md`, (로드맵 대시보드 쓰면) `service-flow.md`.

여기 **안** 들어가는 것 = 흐름·화면, **코드 아키텍처**(모듈 내부 구조) 같은 설계 산출물 → `workflows-coSherpa/docs/concept/`. 결정의 "왜" → `workflows-coSherpa/docs/adr/`.

> 주의: 대시보드가 **파싱하는 서비스 운영 토폴로지**(클라우드·배포 흐름)는 설계가 아니라 계약 → 여기 `service-flow.md`.
> `workflows-coSherpa/docs/concept/architecture.md`(코드 모듈 구조)와는 이름만 비슷한 **다른 문서**다.
