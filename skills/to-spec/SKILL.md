---
name: to-spec
description: "Phase 1 마무리(계약 고정) 산출물인 계약 스펙(docs/spec/) 생성기. accepted ADR + PRD + CONTEXT 용어를 읽어, 구현이 단일 진실원천으로 최우선 참조하는 계약문서(data-schema·api-contract·domain-types 등)와 docs/spec/INDEX.md를 처음 만든다. '/to-spec', '스펙 만들어줘', '계약문서 생성', 'docs/spec 초기화', 'PRD/ADR을 계약 스펙으로', '스펙 문서 작성' 요청 시 활성화. 이미 있는 스펙의 드리프트 정합은 spec-sync 영역 — 이 스킬은 '생성'을 담당한다."
---

# to-spec — 계약 스펙 생성기 (Phase 1 마무리 · 계약 고정)

`grill-with-docs`(ADR) → `to-prd`(PRD) → `to-issues`(슬라이스 목록)로 **결정이 또렷해진 시점**에,
그 결정을 구현이 따라야 할 **계약문서**로 굳혀 `docs/spec/`에 처음 생성한다.
`AGENTS.md`의 "Spec authority" 규약상 `docs/spec/INDEX.md`가 가리키는 문서가 **PRD·ADR보다 우선하는
단일 진실원천**이므로, 이 산출물은 `/fcg-goal` 변환·`/handoff` 전에 존재해야 한다.

> 이 스킬은 **생성(0→1)**, `spec-sync`는 **유지(코드·ADR 드리프트 정합)**. 역할이 다르다.
> 권위·읽기순서 규칙은 `AGENTS.md` "Spec authority"를 따른다(여기 복붙하지 않음).

## 언제 도나
- **Phase 1 마무리(계약 고정 단계).** `to-prd`·`to-issues` 직후, 설계 결정(아래 7항목)이 굳었을 때 사용자가 수동 실행.
- `/fcg-goal` 변환·`/handoff` **직전**이 정위치. 구현 모델이 `docs/spec/INDEX.md`를 최우선으로 읽기 때문.
- 이미 `docs/spec/`가 있고 코드와 어긋난 걸 맞추는 거라면 → 이 스킬이 아니라 `spec-sync`.

## 계약 vs 설계 — 무엇을 docs/spec/에 넣나 (핵심 경계)

**계약(contract) = 코드가 반드시 따라야 하는 인터페이스. PRD/ADR을 override. → `docs/spec/`**

| 계약문서 | 파일 | 담는 것 |
|---|---|---|
| 데이터 스키마 | `docs/spec/data-schema.md` | 테이블·엔티티·관계·제약·인덱스·마이그레이션 규칙 |
| API 계약 | `docs/spec/api-contract.md` | 엔드포인트, 요청/응답 페이로드, 상태코드, **에러 응답 포맷** |
| 공개 타입/도메인 모델 | `docs/spec/domain-types.md` | 공유 인터페이스, enum, value object, DTO |
| (이벤트 기반이면) 이벤트 계약 | `docs/spec/events.md` | 큐·웹훅·토픽 메시지 스키마 |
| (필요시) 설정 계약 | `docs/spec/config.md` | env var, feature flag 키·타입·기본값 |
| (대시보드 쓰면) 서비스 흐름 | `docs/spec/service-flow.md` | 로드맵 대시보드 「서비스 흐름」 탭이 파싱하는 Groups·Components 표(배포 경계·구성요소·`depends_on`·phase). 스키마=`docs/spec/data-schema.md` §서비스 흐름 입력 계약 |

**설계(design) = 모양·근거 설명. 강제력 약하고 변동 잦음 → `docs/spec/`에 넣지 말 것.**

| 비계약 문서 | 둘 곳 | 비고 |
|---|---|---|
| 사용 흐름·유스케이스 (`flow.md`) | `docs/design/flow.md` | 상태머신·시퀀스. 행위 명세지 인터페이스 계약 아님 |
| 화면/UI 설계 (`screens.md`) | `docs/design/screens.md` | 변동 잦아 계약화 부적합 |
| 코드 아키텍처 (`architecture.md`) | `docs/design/architecture.md` | 모듈 경계·의존 방향. 결정 자체는 `docs/adr/` |
| 기술적 결정의 "왜" | `docs/adr/` | append-only 이력 |
| 비기능 요건 | 성격 따라 분기 | "에러 응답 포맷"=계약(spec), "p95 200ms"=설계(design/PRD) |

> 헷갈리면 기준 하나: **다른 모듈/외부가 의존하는 안정 인터페이스인가?** 예면 계약(spec), 아니면 설계(design).

> ⚠ 이름 혼동 주의(`architecture.md` 두 개): **코드 아키텍처**(모듈 내부 구조·의존 방향)는 설계 →
> `docs/design/architecture.md`. 반면 로드맵 대시보드가 **파싱하는 서비스 운영 토폴로지**(클라우드·배포
> 흐름)는 기계가 의존하는 안정 인터페이스라 **계약** → `docs/spec/service-flow.md`. 같은 듯 다른 문서다.

## 절차
1. **입력 수집.** `docs/adr/`의 **accepted** ADR(superseded 제외), `docs/prd/PRD.md`, `docs/issues/*.md`,
   `CONTEXT.md` 용어, 있으면 `docs/design/*`를 읽는다.
2. **계약 항목 추출.** 위 "계약" 표 기준으로 굳은 인터페이스만 골라낸다. 흐름·화면·아키텍처 근거는 spec에 넣지 않는다.
3. **계약문서 작성.** 해당되는 `docs/spec/*.md`만 만든다(불필요한 파일 생성 금지). 각 결정은 **출처 ADR 번호를
   인용**한다. 용어는 `CONTEXT.md`와 일치시킨다.
4. **INDEX.md 생성/갱신.** 만든 계약문서를 `docs/spec/INDEX.md` 표에 등록한다(형식 아래).
5. **비계약 분류.** 흐름·화면·아키텍처 내용이 입력에 섞여 있으면 `docs/design/`의 해당 문서로 옮기거나 가리키게 한다.
6. **요약 보고.** 만든 계약문서, design으로 분류한 것, **결정이 안 나 비워둔 칸**(→ grill-with-docs로 보완 권유)을 보고한다.

## 가드레일
- **결정 안 난 걸 지어내지 않는다.** 입력에 근거가 없으면 그 섹션을 `TODO(미결정)`로 두고 사용자에게 알린다.
  임의로 스키마·엔드포인트를 발명하면 그게 곧 잘못된 단일 진실원천이 된다.
- **PRD/ADR을 재서술하지 않는다.** 의도·근거가 아니라 **인터페이스**만 적는다. 중복 산문 금지.
- **계약만 docs/spec/에.** 흐름·화면·아키텍처는 `docs/design/` 또는 `docs/adr/`로. 경계는 위 표.
- **코드를 만들거나 고치지 않는다.** 구현은 `/fcg-goal`(TDD) 영역. 이 스킬의 쓰기 대상은 `docs/spec/`와 `docs/design/`(분류 이동분)뿐.
- **이후 유지는 spec-sync에 넘긴다.** 생성 후 코드가 진화하면 드리프트 정합은 `spec-sync`가 맡는다.

## 산출물 frontmatter (프로젝트 문서 규약)
각 `docs/spec/*.md` 상단:
```markdown
---
title: <문서명>
created: <YYYY-MM-DD>
resolved: false
status_notes: <한 줄 상태 요약>
related: [docs/prd/PRD.md, docs/adr/NNNN-*.md, docs/design/flow.md]
---
```

## `docs/spec/INDEX.md` 형식
구현 에이전트가 진실원천으로 최우선하는 인덱스. (spec-sync도 같은 형식을 유지한다.)
```markdown
# Current contract specs (single source of truth)

| Spec | File | Covers |
|---|---|---|
| Data schema | docs/spec/data-schema.md | DB tables, relations |
| API contract | docs/spec/api-contract.md | HTTP endpoints, payloads, errors |
| Domain types | docs/spec/domain-types.md | shared interfaces, enums, DTOs |
| Service flow | docs/spec/service-flow.md | dashboard service-flow topology (Groups·Components) |
```
