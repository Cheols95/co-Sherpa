---
name: to-spec
description: "workflows/docs/spec/가 아직 없을 때 PRD/ADR을 계약 스펙으로 처음 만드는(0→1 생성) 생성기 — 이미 workflows/docs/spec/가 있고 드리프트만 맞추는 건 spec-sync 영역(이건 생성 전용). Phase 1 마무리(계약 고정) 산출물로, accepted ADR + PRD + CONTEXT 용어를 읽어 구현이 단일 진실원천으로 최우선 참조하는 계약문서(data-schema·api-contract·domain-types 등)와 workflows/docs/spec/INDEX.md를 만든다. '/to-spec', '스펙 만들어줘', '계약문서 생성', 'workflows/docs/spec 초기화', 'PRD/ADR을 계약 스펙으로', '스펙 문서 작성' 요청 시 활성화."
---

# to-spec — 계약 스펙 생성기 (Phase 1 마무리 · 계약 고정)

`/concept` 산출 ADR → `to-prd`(PRD)로 **결정이 또렷해진 시점**에,
그 결정을 구현이 따라야 할 **계약문서**로 굳혀 `workflows/docs/spec/`에 처음 생성한다.
(이 계약을 먼저 고정한 뒤 `to-issues`가 그 위에서 작업 슬라이스를 자른다.)
`AGENTS.md`의 §Spec authority에 따라 `workflows/docs/spec/INDEX.md`가 가리키는 문서가 **PRD·ADR보다 우선하는
단일 진실원천**이므로, 이 산출물은 `/build` 변환·`/handoff` 전에 존재해야 한다.

> 이 스킬은 **생성(0→1)**, `spec-sync`는 **유지(코드·ADR 드리프트 정합)**. 역할이 다르다.
> 권위·읽기순서 규칙은 `AGENTS.md` §Spec authority를 따른다(여기 복붙하지 않음).

## 언제 도나
- **계약 고정 단계.** `to-prd` 직후(설계 결정 아래 7항목이 굳었을 때), **`to-issues` 전**에 사용자가 수동 실행 — 계약을 먼저 고정해야 issues가 그 인터페이스 위에서 슬라이스된다.
- `/to-issues`·`/build` 변환·`/handoff` **전**이 정위치. 구현 모델이 `workflows/docs/spec/INDEX.md`를 최우선으로 읽기 때문.
- 이미 `workflows/docs/spec/`가 있고 코드와 어긋난 걸 맞추는 거라면 → 이 스킬이 아니라 `spec-sync`.

## 계약 vs 설계 — 무엇을 workflows/docs/spec/에 넣나 (핵심 경계)

**계약(contract) = 코드가 반드시 따라야 하는 인터페이스. PRD/ADR을 override. → `workflows/docs/spec/`**

| 계약문서 | 파일 | 담는 것 |
|---|---|---|
| 데이터 스키마 | `workflows/docs/spec/data-schema.md` | 테이블·엔티티·관계·제약·인덱스·마이그레이션 규칙 |
| API 계약 | `workflows/docs/spec/api-contract.md` | 엔드포인트, 요청/응답 페이로드, 상태코드, **에러 응답 포맷** |
| 공개 타입/도메인 모델 | `workflows/docs/spec/domain-types.md` | 공유 인터페이스, enum, value object, DTO |
| (이벤트 기반이면) 이벤트 계약 | `workflows/docs/spec/events.md` | 큐·웹훅·토픽 메시지 스키마 |
| (필요시) 설정 계약 | `workflows/docs/spec/config.md` | env var, feature flag 키·타입·기본값 |
| (대시보드 쓰면) 서비스 흐름 | `workflows/docs/spec/service-flow.md` | 로드맵 대시보드 「서비스 흐름」 탭이 파싱하는 Groups·Components 표(배포 경계·구성요소·`depends_on`·phase). 표 형식의 권위 출처는 `workflows/dashboard/engines/roadmap.sh` 파서 주석 + `roadmap-selftest.sh`이며, to-spec이 `workflows/docs/spec/data-schema.md` §서비스 흐름 입력 계약으로 옮긴다(없으면 생성) |

**비계약 설계 = 모양·근거 설명. 강제력 약하고 변동 잦음 → `workflows/docs/spec/`에 넣지 말 것.**

| 비계약 문서 | 둘 곳 | 비고 |
|---|---|---|
| 사용 흐름·유스케이스 (`flow.md`) | `workflows/docs/design/flow.md` | 상태머신·시퀀스. 행위 명세지 인터페이스 계약 아님 |
| 화면/UI 설계 (`screens.md`) | `workflows/docs/design/screens.md` | 변동 잦아 계약화 부적합 |
| 코드 아키텍처 (`architecture.md`) | `workflows/docs/design/architecture.md` | 모듈 경계·의존 방향. 결정 자체는 `workflows/docs/adr/` |
| 기술적 결정의 "왜" | `workflows/docs/adr/` | append-only 이력 |
| 비기능 요건 | 성격 따라 분기 | "에러 응답 포맷"=계약(spec), "p95 200ms"=비계약 설계/PRD |

> 헷갈리면 기준 하나: **다른 모듈/외부가 의존하는 안정 인터페이스인가?** 예면 계약(spec), 아니면 비계약 설계.

> ⚠ 이름 혼동 주의(`architecture.md` 두 개): **코드 아키텍처**(모듈 구조·의존)=설계 →
> `workflows/docs/design/architecture.md`, 대시보드가 **파싱하는 서비스 운영 토폴로지**(배포 흐름)=계약 →
> `workflows/docs/spec/service-flow.md`. 전문은 `workflows/docs/design/README.md` + `workflows/docs/spec/README.md` 참조.

## 동결 전 게이트 — 결정표면 회계 + 독립 의도-감사 (절차 0단계)

계약을 굳히기 전 두 가지를 통과해야 한다 — 전문은 `workflows/docs/design/AGENTS.md` §Account the decision surface +
§Pre-freeze intent-audit(**작업 전 필독**; 단 `freeze`가 sealed로 부른 경우 ①에서 이미 수행 → 생략):

1. **결정표면 회계** — 엔티티 × 4렌즈(구조·행위·기술·계약)로 load-bearing 결정을 열거, 모든 슬롯이
   `grounded`/`질문해 답받음`/`튜닝값 보류` 중 하나가 될 때까지(미결정 처리는 아래 §가드레일).
2. **독립 의도-감사 1회** — 계획 비작성 서브에이전트(없으면 자기-감사)가 "조용히 채워진 추측"을 사냥,
   발견은 몰래 패치 금지·**사용자 질문으로 종결**.

> 이 게이트가 얕은 결정 정산의 면죄부가 되면 안 된다 — 여기서 뭔가 나오면 대화를 너무 일찍 닫은 것.

## 절차
1. **입력 수집.** `workflows/docs/adr/`의 **accepted** ADR(superseded 제외), `workflows/docs/prd/PRD.md`, `CONTEXT.md` 용어,
   있으면 `workflows/docs/design/*`(및 재실행이라 이미 있으면 `workflows/docs/issues/*`)를 읽는다. **계약의 출처는 ADR·PRD이지 issues가 아니다**(to-spec은 to-issues보다 먼저 돈다).
2. **계약 항목 추출.** 위 "계약" 표 기준으로 굳은 인터페이스만 골라낸다. 흐름·화면·아키텍처 근거는 spec에 넣지 않는다.
3. **계약문서 작성.** 해당되는 `workflows/docs/spec/*.md`만 만든다(불필요한 파일 생성 금지). 각 결정은 **출처 ADR 번호를
   인용**한다. 용어는 `CONTEXT.md`와 일치시킨다.
4. **INDEX.md 생성/갱신.** 만든 계약문서를 `workflows/docs/spec/INDEX.md` 표에 등록한다(형식·`TODO(미결정)` 칸
   표기 규칙은 아래 §`workflows/docs/spec/INDEX.md` 형식 — 구현이 미결정 placeholder를 동결 계약으로 오독하지 않게).
5. **비계약 분류.** 흐름·화면·아키텍처 내용이 입력에 섞여 있으면 `workflows/docs/design/`의 해당 문서로 옮기거나 가리키게 한다.
6. **요약 보고.** 만든 계약문서, concept으로 분류한 것, **결정이 안 나 비워둔 칸**(→ `/concept`으로 보완 권유)을 보고한다.

## 계약문서 품질 floor (칸 채우기 ≠ 계약)

각 `workflows/docs/spec/*.md`에서 **내용이 채워진 항목**은 아래를 통과해야 한다. 가드레일대로 정당하게
`TODO(미결정)`로 둔 칸은 floor 면제 — "통과한 계약"이 아니라 "추적 중 미결정"으로 본다(채운 척
위장 금지). 구조만 갖추고 내용이 빈 계약문서(hollow shell)는 **없느니만 못하다** — 구현 모델이
"스펙이 있다"고 믿고 빈 계약을 그대로 따르기 때문이다.

- **검증 가능(verifiable)** — 모든 제약을 "지켜졌나?"로 판정할 수 있게 적는다. "적절히 처리한다" 류 금지.
- **반례 명시(counter-case)** — "~해야 한다"는 짝이 되는 "~하면 안 된다"와 함께 — **단 부정이 판별력을 더할 때만**(이미 값으로 다른 경우가 배제되면 짝을 강제하지 않는다). (예: "id는 BIGINT" ↔ "INTEGER면 안 됨".)
- **메커니즘(mechanism)** — 결과만이 아니라 입력→처리→출력. ("X가 된다"가 아니라 "A·B가 동시에 성립하면 X로 전이".)
- **엣지 구체화(concrete edge)** — 경계 케이스마다 구체적 처분을 적는다. 모호한 수식어("견고하게"·"유연하게") 금지.
- **있을 자리값(consequence-of-absence)** — 한 줄을 지웠을 때 무엇이 깨지는지 답할 수 없으면, 그 줄은 계약이 아니다(빼거나 `workflows/docs/design/`으로).

> 비개발자에게 특히 위험한 함정: 칸이 채워진 스펙을 보고 "다 됐다"고 착각하는 것. 빈 계약이 그 착각을 만든다.

## 가드레일
- **핵심 기술 선택이 비어 있으면 계약을 고정하지 않는다.** 저장 방식·전달 형태(서비스/라이브러리/CLI/UI)·
  스택처럼 *바뀌면 계약 전체가 흔들리는* 선택(load-bearing)이 ADR/PRD에 명시 결정으로 없으면, 그 칸을
  `TODO(미결정)`로 두고 **사용자에게 명시적으로 올려** `/concept`으로 보완을 권한다. 조용히 기본값을
  골라 채우면, 반대할 줄 몰랐던 사용자가 빌드가 끝나서야 잘못된 선택을 발견한다.
- **결정 안 난 걸 지어내지 않는다.** 입력에 근거가 없으면 그 섹션을 `TODO(미결정)`로 두고 사용자에게 알린다.
  임의로 스키마·엔드포인트를 발명하면 그게 곧 잘못된 단일 진실원천이 된다.
- **PRD/ADR을 재서술하지 않는다.** 의도·근거가 아니라 **인터페이스**만 적는다. 중복 산문 금지.
- **계약만 workflows/docs/spec/에.** 흐름·화면·아키텍처는 `workflows/docs/design/` 또는 `workflows/docs/adr/`로. 경계는 위 표.
- **코드를 만들거나 고치지 않는다.** 구현은 `/build`(TDD) 영역. 이 스킬의 쓰기 대상은 `workflows/docs/spec/`와 `workflows/docs/design/`(분류 이동분)뿐.
- **이후 유지는 spec-sync에 넘긴다.** 생성 후 코드가 진화하면 드리프트 정합은 `spec-sync`가 맡는다.

## 산출물 frontmatter (프로젝트 문서 규약)
각 `workflows/docs/spec/*.md` 상단:
```markdown
---
title: <문서명>
created: <YYYY-MM-DD>
resolved: false
status_notes: <한 줄 상태 요약>
related: [workflows/docs/prd/PRD.md, workflows/docs/adr/NNNN-*.md, workflows/docs/design/flow.md]
---
```

## `workflows/docs/spec/INDEX.md` 형식
구현 에이전트가 진실원천으로 최우선하는 인덱스. (spec-sync도 같은 형식을 유지한다.)
> `TODO(미결정)` 칸이 남은 스펙은 Covers에 `(미결정 칸 있음)` 표기 + frontmatter `resolved:false`를
> 유지하고, 동결(모든 칸 결정)되면 그 표기를 제거한다.
```markdown
# Current contract specs (single source of truth)

| Spec | File | Covers |
|---|---|---|
| Data schema | workflows/docs/spec/data-schema.md | DB tables, relations |
| API contract | workflows/docs/spec/api-contract.md | HTTP endpoints, payloads, errors |
| Domain types | workflows/docs/spec/domain-types.md | shared interfaces, enums, DTOs |
| Service flow | workflows/docs/spec/service-flow.md | dashboard service-flow topology (Groups·Components) |
```
