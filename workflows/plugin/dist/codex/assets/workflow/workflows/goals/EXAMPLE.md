# workflows/goals/EXAMPLE.md — 변환 정답지 (issue → 3파일 goal 계약)

> **이 파일은 goal이 아니라 문서다.** discovery rule(이름이 숫자로 시작하거나
> `_meta.md`인 파일만 goal로 인식 — `workflows/goals/AGENTS.md`)이 무시하므로 체인·게이트에
> 영향이 없고, `0-example`과 달리 첫 변환 후에도 **영구히 남는다**.
>
> **역할 분담** — `workflows/goals/0-example.*` = *실행되는* 교육용 placeholder(새 템플릿에서
> 체인이 green 되는 걸 관찰; 첫 모드 B 변환이 삭제). 이 문서 = *변환 품질의 기준*
> (모드 B 변환 전, finding을 goal로 promote하기 전에 1회 참조).
>
> 규약 본체는 `workflows/goals/AGENTS.md` · `workflows/docs/goal-design.md` §1·§1.5 — 이 문서는 예시일
> 뿐 규약을 재정의하지 않는다. **모양을 베끼되 단어를 베끼지 마라** — 아래의 스택·
> 엔티티·파일 경로·명령은 전부 가상의 예다. 실제 변환에서는 그 프로젝트의 source
> of truth를 런타임에 찾아 쓴다.

---

## 입력 — 가상의 이슈 `workflows/docs/issues/003-cancel-booking.md`

```markdown
---
depends: [001, 002]
risk: RISKY
---
# 003 — 예약 취소

Status: ready-for-agent

## What to build

사용자가 확정된 예약을 취소할 수 있다. 취소된 예약의 슬롯은 즉시 재예약
가능해진다. 이미 시작된 예약은 취소할 수 없다.

## Acceptance criteria

- [ ] confirmed 상태의 예약만 취소 가능
- [ ] 취소 시 해당 슬롯이 검색에 다시 노출
- [ ] 시작 시각이 지난 예약의 취소 요청은 409를 반환

## Blocked by

- 001, 002
```

---

## 출력 1 — `workflows/goals/3-cancel-booking.md` (미션)

```markdown
---
risk: RISKY
---
# Goal 3 — 예약 취소 규칙 강제

> 이 goal을 active로 잡은 에이전트는 먼저 `workflows/guidelines/goal-iteration.md`를
> 읽어 iteration 프로토콜을 확인할 것.

## Mission

취소 규칙이 계약(workflows/docs/spec/api-contract.md §cancel)대로 강제된다:
confirmed 상태에서만 취소되고, 시작 시각이 지난 예약은 409로 거부되며,
취소된 예약의 슬롯은 검색에 재노출된다.

## Completion Conditions

1. Every cancellation rule in `workflows/docs/spec/api-contract.md` §cancel
   (CANCEL-R* id) has a test that exercises it.
2. This goal's gate passes `workflows/scripts/check-gate-rigor.sh` — the universal
   claim above forces the gate to enumerate, not sample.

## Sources Of Truth

- 규칙 집합: `grep -oE 'CANCEL-R[0-9]+' workflows/docs/spec/api-contract.md`
- 상태 집합: `workflows/docs/spec/domain-types.md` BookingStatus enum

## Verification

    bash workflows/goals/3-cancel-booking.gates.sh
    bash workflows/scripts/completion-check.sh

## Forbidden actions

- 취소 외 엔드포인트/모듈 수정 금지 — 발견한 부채는 finding으로 큐잉.
- BookingStatus enum 값 추가/변경 금지 — 계약 변경은 사용자 결정.
```

**왜 이렇게 생겼나**

- **번호 `3` = 체인 순서 라벨**일 뿐 이슈 번호 `003`과 1:1 매핑이 아니다 —
  연결은 slug(`cancel-booking`)로 한다 (`AGENTS.md` §Phase 1→2 bridge).
- **`risk: RISKY`는 이슈 frontmatter에서 그대로 운반**됐다(엣지·검증 규칙을
  명시한 슬라이스). green 후 전진 전에 비저자 마감 리뷰 1회가 발동한다
  (`workflows/goals/AGENTS.md` §Risk tier). 이슈에 risk가 없으면 변환 시 휴리스틱으로
  판정하되, **미지정은 MECHANICAL이 아니라 미판정**이다.
- **"every"는 진심일 때만 쓴다** — 쓰는 순간 rigor 검사가 gate에 enumeration을
  요구한다. 거짓 universality도, 검사를 피하려고 "every"를 지우는 것도 금지.
- **Forbidden actions가 또렷해야** 루프 중 scope creep 대신 finding 큐잉이
  작동한다 — 자동 큐잉의 전제는 또렷한 goal 경계다.

---

## 출력 2 — `workflows/goals/3-cancel-booking.gates.sh` (기계 검증, chmod +x)

```bash
#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

source "$ROOT/workflows/scripts/_gate-cache.sh"

GATE_INPUTS=(
  workflows/docs/spec/api-contract.md
  tests/booking
  workflows/goals/3-cancel-booking.gates.sh
  workflows/goals/3-cancel-booking.md
  workflows/scripts/_gate-cache.sh
)

if gate_cache_hit "3-cancel-booking" "${GATE_INPUTS[@]}"; then
  echo "[cache hit] goal 3-cancel-booking inputs unchanged"
  exit 0
fi

PASS=true

# 3.1 -- Universal claim: "every cancellation rule has a test."
# The claim is universal, so the gate ENUMERATES the source of truth
# (the contract's rule ids) instead of sampling one rule.
echo "[3.1] every CANCEL-R* rule in the contract is exercised by a test"
MISSING=()
while IFS= read -r rule; do
  grep -rq "$rule" tests/booking/ || MISSING+=("$rule")
done < <(grep -oE 'CANCEL-R[0-9]+' workflows/docs/spec/api-contract.md | sort -u)
if [ "${#MISSING[@]}" -eq 0 ]; then
  echo "    [PASS]"
else
  echo "    [FAIL] -- rules with no test:"
  printf '        %s\n' "${MISSING[@]}"
  PASS=false
fi

# 3.2 -- Negative universal: the bypass flag appears nowhere in src.
echo "[3.2] no force_cancel bypass anywhere in src/"
if grep -rn "force_cancel" src/ >/dev/null 2>&1; then
  echo "    [FAIL] -- forbidden bypass 'force_cancel' found"
  PASS=false
else
  echo "    [PASS]"
fi

# 3.3 -- Gate rigor self-check.
echo "[3.3] gate rigor"
if bash "$ROOT/workflows/scripts/check-gate-rigor.sh" "$ROOT/workflows/goals/3-cancel-booking.md" >/dev/null 2>&1; then
  echo "    [PASS]"
else
  echo "    [FAIL]"
  bash "$ROOT/workflows/scripts/check-gate-rigor.sh" "$ROOT/workflows/goals/3-cancel-booking.md" | sed 's/^/      /'
  PASS=false
fi

if [ "$PASS" = true ]; then
  gate_cache_save "3-cancel-booking" "${GATE_INPUTS[@]}"
  exit 0
fi
exit 1
```

**왜 이렇게 생겼나**

- **게이트 ≠ convention police.** "취소 로직이 옳은가"는 테스트가 검증한다 —
  gate는 (a) 계약 규칙 ↔ 테스트 존재의 **enumeration**, (b) **negative
  universal** grep, (c) **rigor 앵커**만 소유한다. 회의적 휴리스틱: *"이
  불변식이 깨지면 어떤 테스트가 red가 되나?"* — 답이 있으면 그 검사는
  테스트 소유, gate에서 빼라 (`workflows/docs/goal-design.md` §1.5).
- **나쁜 gate의 예**: `curl /bookings/42/cancel` — 한 케이스 샘플. 42번만
  맞으면 green이 된다(narrow-gate cheat). 좋은 gate는 source of truth를
  **순회**한다 — gate에 엔티티/규칙 이름을 직접 타이핑하고 있다면 멈추고
  enumeration으로 교체하라.
- `_gate-cache.sh` source + `GATE_INPUTS` 선언 + `gate_cache_hit`/`save` —
  입력이 안 변한 재실행은 캐시로 통과시켜 전체 sweep을 싸게 유지한다.

---

## 출력 3 — `workflows/goals/3-cancel-booking.next-task.sh` (힌트, chmod +x)

```bash
#!/usr/bin/env bash
# advisory only -- never gates.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! compgen -G "tests/booking/*cancel*" >/dev/null; then
  echo "TASK: RED -- write the first failing cancellation test (spec: workflows/docs/spec/api-contract.md #cancel)"
elif ! bash "$ROOT/workflows/goals/3-cancel-booking.gates.sh" >/dev/null 2>&1; then
  echo "TASK: GREEN -- make the remaining cancellation rules pass, then re-run the gate"
else
  echo "TASK: goal 3-cancel-booking is green -- run workflows/scripts/active-check.sh to advance"
fi
```

**왜 이렇게 생겼나** — 힌트는 **진행 상태 탐지**만 한다(테스트 파일 존재,
gate fail 여부 — 구현 형태가 아니라 진행 상태에 대한 명제). 함수명·테스트
제목·구현 방식을 박지 않는다: *"에이전트가 더 좋은 대안을 찾으면 이 단어도
같이 고쳐야 하나?"* — 그렇다면 그 단어는 mechanism이다, 빼라
(`workflows/guidelines/goal-iteration.md` §Designing next-task hints).

---

## 변환 체크리스트 (모드 B — 슬라이스 하나마다)

1. 이슈 frontmatter `risk:` 운반 — 없으면 휴리스틱 판정(미지정 ≠ MECHANICAL).
2. Mission의 universal claim ↔ gate enumeration이 짝을 이루는가.
3. gate에 엔티티/규칙 이름 하드코딩 없음 — source of truth 순회인가.
4. `_gate-cache.sh` source + `GATE_INPUTS` + rigor self-check 포함, `chmod +x`.
5. 횡단 검사(lint/typecheck/test/build)는 이 goal이 아니라 `_meta` 소관 —
   **첫 변환이면 `workflows/goals/_meta.gates.sh`의 `META_CHECKS`/`GATE_INPUTS`를 스택에 맞게 채우고
   `bash workflows/goals/_meta.gates.sh`로 1회 실행 검증**(build 스킬 모드 B 절차). 안 채우면 _meta가
   vacuous-pass = 회귀 안전망 부재 → `diagnose.sh`가 경고.
6. Forbidden actions에 scope 경계 명시.
7. gate/`_meta`가 테스트 러너를 호출하면 디렉토리가 아니라 파일/글롭 인자 —
   디렉토리 발견 의미는 런타임 버전마다 달라 wiring-red 유발(`workflows/docs/goal-design.md` §1.5).
8. 첫 변환이면 `workflows/goals/0-example.*` 삭제(부트스트랩 규약) — 이 `EXAMPLE.md`는
   문서라 삭제 대상이 아니다.
