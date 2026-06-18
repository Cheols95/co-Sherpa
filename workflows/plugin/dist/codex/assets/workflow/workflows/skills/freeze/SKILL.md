---
name: freeze
description: "닫힌 기능을 한 번의 호출로 계약·PRD·이슈·graph-lint까지 봉인하는 sealed 번들 (Phase 1 → 2 동결). 호출 자체가 유일한 인간 승인점이다. '/freeze', '동결', '기능 봉인', '계약 고정', 'freeze 기능X', concept가 '기능 X 닫힘 — /freeze ready' 선언한 직후 활성화. concept으로 결정표면이 닫힌 기능에만 쓴다."
---

# freeze — sealed 동결 번들 (Phase 1 → 계약)

`concept`이 **"기능 X 닫힘 — /freeze ready"**를 선언한 기능을, 한 번의 호출로
**의도감사 → PRD → 계약 스펙 → 이슈 → graph-lint**까지 봉인한다.
**이 호출 자체가 유일한 인간 승인점이다** — 호출 = "이 동결을 승인한다"(다른 중간 승인점 없음).

> 규칙 권위는 `workflows/docs/design/AGENTS.md`(Phase 1) / `workflows/goals/AGENTS.md` §Gate validity — **봉인 시작 전 반드시 읽는다**. 체크리스트 규약은 `workflows/docs/design/README.md`.
> 이 스킬은 그 종료를 **봉인**하는 오케스트레이터다. 새로 만드는 본체는 ③ spec 증분 확장 하나뿐 —
> 나머지는 기존 스킬(to-prd·to-spec·to-issues)을 sealed로 수행한다.

## 진입 전제
- 대상 기능의 `workflows/docs/design/checklist.md`가 **닫혀 있어야** 한다(미표기 `[ ]` 0개 **그리고**
  미정산 `[>]` 0개). 안 닫혔으면 **중단** — `concept`로 돌려보낸다(닫힘 선언이 없었다면 freeze 진입 자체가 오류).
- 동결 단위 = **기능 1개**(tracer-bullet). 기능 A를 봉인하는 동안 기능 C는 계속 concept 진행 가능.

## 전 단계 공통 규율 — sealed mode
- **사용자에게 중간 질문 금지.** 모든 미결정은 concept checklist에 이미 닫혀 있다 — 단계 스킬이 평소
  사용자에게 묻는 것(예: `to-prd`의 test seam 확인)은 **checklist의 해당 슬롯에서 답을 가져와** 억제한다.
- **미결정/모순을 발견하면 패치하지 말고 중단** → 사용자에게 보고 → `concept` 재개. (조용한 기본값 = freeze가 막으려는 바로 그 실패.)

---

## ① 독립 의도감사 (2방향) — 문지기

PRD 진행 **전**, 계획 비작성 서브에이전트 1회(없으면 명시적 자기-감사 패스)로 **(a) disposition**(과잉주장 사냥)
+ **(b) residual-enumeration**(과소열거 사냥 — 없으면 닫힘 조건이 위조 가능) 두 감사를 돌린다. (a)/(b) 정의·
4렌즈·근거 전문은 `workflows/docs/design/AGENTS.md` §Pre-freeze intent-audit(**봉인 전 필독**).

발견이 있으면 **중단** → 사용자 질문으로 종결 → checklist 갱신 후 freeze 재호출(닿은 슬롯만 1회 재walk, 또 나오면 escalate — 열린 루프 금지).

> 이것이 `to-spec` §"동결 전 게이트"를 freeze로 끌어올린 것 — ③에서 `to-spec`을 sealed로 부를 때 그
> 0단계 게이트는 **이미 수행됨, 생략**(중복 방지).

## ② to-prd (sealed)

`to-prd` 스킬대로 대화 컨텍스트를 `workflows/docs/prd/PRD.md`로 합성·발행한다. 단 **test seam은 checklist의
기술/계약 슬롯에서 가져온다**(사용자 재확인 금지 — 미결정이면 ①에서 걸렸어야 한다).

## ③ spec 라우팅 — 생성 또는 증분 확장  ★이 스킬의 유일한 신규 본체

`workflows/docs/spec/INDEX.md` 존재 여부로 분기한다:

- **없음 → `to-spec`** (0→1 생성). 위 ①이 0단계 게이트를 이미 했으므로 그건 생략하고, 계약문서 생성 +
  품질 floor(검증가능·반례·메커니즘·구체엣지·있을자리값)만 적용한다.
- **있음 → 증분 확장** (`to-spec`도 `spec-sync`도 안 하는 일 — freeze가 직접):
  1. 이 기능의 **계약 항목만 추출**(`to-spec` "계약 vs 설계" 경계 표 적용 — 흐름·화면·아키텍처는 `workflows/docs/design/`).
  2. 기존 **동결 계약과 충돌 검사.** 이 기능의 계약이 이미 동결된 계약과 충돌하면 →
     **이 기능을 수정**하거나 **명시적 ADR supersede 후** 변경한다. 조용한 덮어쓰기 금지.
  3. 해당 `workflows/docs/spec/*.md`에 **delta만 추가** + `workflows/docs/spec/INDEX.md` 갱신. 품질 floor 적용.

> 드리프트 정합(코드↔계약)이 아니다 — 그건 `spec-sync`. 여기는 **새 계약을 기존 위에 얹는** 작업이다.

## ④ to-issues (sealed)

`to-issues` 스킬대로 **tracer-bullet 수직 슬라이스**로 쪼개 `workflows/docs/issues/<NNN>-<slug>.md`를 만든다.
frontmatter `depends:`/`risk:`를 emit하고(프로젝트 `AGENTS.md` §Agent-skills configuration), 계약의
출처는 방금 고정한 `workflows/docs/spec/`다.

## ⑤ graph-lint (하드 게이트)

```bash
bash workflows/scripts/issues-graph-check.sh
```
순환(cycle) 또는 dangling `depends`가 있으면 **freeze 실패** — 이슈 frontmatter를 고치고 다시 돌린다
(exit≠0이면 동결 미완). 이것이 봉인의 마지막 기계 게이트다.

---

## 완료
- `workflows/docs/design/checklist.md`의 그 기능을 **`FROZEN (날짜, freeze 완료 → issues NNN~MMM)`**로 표기.
- 보고: "기능 X 동결 완료 → issues NNN~MMM. 다음: `/build`으로 구현(변환 모드 B)." 사용자 언어로 간결히.

## 동결 후 (일방향)
- 새 기획거리 → `workflows/docs/findings/`(체크리스트 재오픈 아님).
- 동결 결정의 **근본 오류** → 사용자 승인 후 `concept` 재오픈(Phase 1 재진입). 라우팅: 단순 추가/충돌 → findings,
  동결 결정 자체가 틀림 → concept 재오픈. (`workflows/docs/design/AGENTS.md`)
