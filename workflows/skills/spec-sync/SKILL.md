---
name: spec-sync
description: "workflows/docs/spec/가 이미 있을 때 계약 문서 ↔ 코드 ↔ 최신 accepted ADR 드리프트를 정합시키는 관리기(생성 아님 — 0→1 생성은 to-spec). 문서만 고치면 되는 건 직접 갱신하고 코드를 고쳐야 하는 건 finding으로 큐잉한다. 'spec-sync', '스펙 동기화', '계약 문서 최신화', '스펙 드리프트 점검', '스펙 정합성 봐줘' 요청 시 활성화. PRD/ADR 전체를 재작성하지 않는다 — 현재 계약 스펙만 정리한다."
---

# spec-sync — 현재 계약 스펙 정합성 관리기

계약 스펙(`workflows/docs/spec/`의 data-schema·api-contract·public types 등)은 SDD 레이어 — **항상 최신이어야 하는 단일 진실원천**이다. 이 스킬은 그 계약 스펙이 코드·최신 결정과 어긋난 지점을 찾아 **문서를 정합 상태로 되돌린다.** PRD·ADR 이력은 건드리지 않는다.

> 스펙 권위·우선순위·읽기 순서 규칙은 **프로젝트 `AGENTS.md`의 §Spec authority를 따른다** (여기 복붙하지 않는다). 이 스킬은 그 규약을 코드/문서 현실에 맞춰 유지하는 실행기다.

## 언제 도나
- **사용자가 수동으로, Phase 2.5(cycle 사이)에** 실행한다. 자동 트리거가 아니다.
- `/improve-codebase-architecture`와 같은 리듬 — 큰 기능/cycle 완료 후, 또는 `/handoff` 전에 의식적으로 한 번.

## 절차
1. **현재 계약 집합 파악.** `workflows/docs/spec/INDEX.md`가 가리키는 계약 문서들을 읽는다 (없으면 `workflows/docs/spec/` 스캔). 이게 점검 대상이다.
2. **드리프트 점검.** 각 계약 문서를 (a) 실제 코드/스키마/타입, (b) 최신 accepted ADR과 대조한다. 모든 불일치 주장은 **file:line 근거**로 짚는다 — 못 짚으면 추측이지 드리프트가 아니다.
3. **분류해서 처리** (아래 표). 직접 고칠 것 / finding으로 넘길 것 / 사용자에게 물을 것을 가른다.
4. **INDEX.md 갱신.** 새 계약 문서가 생겼거나 사라졌으면 목록을 맞춘다.
5. **요약 보고.** 무엇을 직접 갱신했고, 무엇을 finding으로 남겼고, 무엇이 모호한지 사용자에게 보고한다.

## 처리 분류 (핵심)

| 발견 | 처리 |
|---|---|
| 계약 **문서가** 코드/ADR보다 구버전 (문서만 고치면 정합) | **직접 갱신** — `workflows/docs/spec/` 문서 + `INDEX.md` |
| accepted ADR의 결정이 계약 문서에 아직 반영 안 됨 | **직접 반영** (delta만, 전면 재작성 X) |
| **코드를** 고쳐야 함 (코드가 계약과 어긋나고 코드 쪽이 틀림) | 직접 안 고침 → `workflows/docs/findings/`에 큐잉 (이후 `/build`이 테스트와 함께 처리) |
| 코드·문서 중 어느 쪽이 맞는지 모호 | **사용자에게 질문.** 임의 결정 금지 |
| 계약 문서가 hollow shell(칸만 있고 내용 빔)이거나 품질 floor(검증가능·반례·구체엣지, `to-spec` §품질 floor 참조) 위반 | 채울 근거(우선순위: ①코드 → ②최신 accepted ADR → ③①②가 대체(supersede) 안 한 PRD 결정, 충돌 시 상위 우선)가 있으면 **직접 보강**, 없으면 **finding 또는 사용자 질문**. 단, 칸 내용이 `TODO(미결정)`이면 보강 대상이 아니다(to-spec이 사용자 결정 대기로 비운 칸) — 그대로 두고 finding/질문으로만 처리 |

> 서비스 흐름 계약(`workflows/docs/spec/service-flow.md`)도 같은 규칙: 표가 실제 배포 토폴로지·최신 ADR과 어긋나면
> 문서만 고치면 직접 갱신, 인프라/코드를 고쳐야 하면 finding. (표 형식·권위 출처는 `workflows/skills/to-spec/SKILL.md`
> 서비스 흐름 항목과 `workflows/docs/spec/README.md` 참조 — 코드 `architecture.md`와는 다른 문서.)

## 가드레일
- **코드를 직접 고치지 않는다.** 테스트 없는 코드 변경은 TDD 엔진(`/build`)의 영역 — 여기선 finding으로 넘긴다.
- **PRD/ADR을 재작성하지 않는다.** PRD는 의도(동결), ADR은 이력(append-only). 이 스킬의 쓰기 대상은 `workflows/docs/spec/`와 `workflows/docs/spec/INDEX.md`뿐이다.
- **대량 재작성 금지.** 드리프트 난 delta만 손본다. 잘 써둔 문서를 통째로 다시 쓰지 않는다.
- **모호하면 멈추고 묻는다.** 코드를 스펙에 맞춰 굳히거나 그 반대를 하기 전에, 어느 쪽이 의도인지 불분명하면 사용자 확인.

## finding 큐잉 형식
코드 수정이 필요한 발견은 `workflows/docs/findings/`에 적는다 — 형식·frontmatter는 `finding` 스킬 규약을 따른다. TL;DR에 "계약 `<문서>`와 코드 `<file:line>`가 어긋남, 코드 쪽 수정 필요"를 명시한다.

## `workflows/docs/spec/INDEX.md` 형식
현재 유효한 계약 문서의 목록 — 구현 에이전트가 진실원천으로 최우선하는 인덱스. **형식·표기는
`workflows/skills/to-spec/SKILL.md` §`workflows/docs/spec/INDEX.md` 형식이 단일 출처**(표 헤더 `| Spec | File | Covers |`,
`TODO(미결정)` 칸은 Covers에 `(미결정 칸 있음)`+frontmatter `resolved:false`, 동결 시 제거) — 여기 복붙하지
않고 그대로 따른다. 파일이 없으면 첫 계약 문서가 생길 때 lazily 만든다.
