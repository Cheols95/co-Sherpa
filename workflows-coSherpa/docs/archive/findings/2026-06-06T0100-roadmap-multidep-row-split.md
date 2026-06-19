---
title: "roadmap.sh가 의존성 2개 이상인 이슈의 DATA 레코드를 줄바꿈으로 쪼갠다"
created_at: 2026-06-06T01:00:00Z
resolved: true
status_notes: "FIXED 2026-06-06 — roadmap.sh deps 추출에 `| tr '\\n' ' '` 평탄화 적용(옵션 A). roadmap-selftest.sh deps 그룹에 2-dep 픽스처(006-multidep) + 단언 추가(RED→GREEN 확인). mock 005-checkout을 001+004 2-dep로 복원해 end-to-end 검증."
priority: P1
related:
  - workflows-coSherpa/dashboard/engines/roadmap.sh
  - workflows-coSherpa/docs/spec/data-schema.md
---

# roadmap.sh가 의존성 2개 이상인 이슈의 DATA 레코드를 줄바꿈으로 쪼갠다

## TL;DR

`## Blocked by`에 의존 이슈가 **2개 이상**이면 대시보드 생성기가 그 기능 노드의
DATA 레코드를 깨뜨린다(필드 밀림 + 유령 중복 노드 + `readyCount` 오계산). EverShop
mock의 005-checkout(001·004 두 의존)에서 처음 재현됨(2026-06-06). 기존 대시보드
빌드 이슈는 전부 직렬(단일 의존)이라 잠재 결함이 드러나지 않았다.

## Body

`workflows-coSherpa/dashboard/engines/roadmap.sh`:

- L87-88: `deps="$(awk '…blocked by…' | grep -oE '\b[0-9]{3}\b' | sort -u | …)"`
  → `grep -o`/`sort`가 매칭마다 줄을 나눠 `deps`가 **여러 줄 문자열**("001\n004")이 된다.
- L103: `row="${id}|${deps}|${gate}|…"` 로 그 여러 줄 deps를 파이프 구분 한 줄
  레코드 한가운데에 끼워넣는다 → 레코드에 줄바꿈이 박힌다.
- L113 `while IFS='|' read -r … <<EOF $FEATURE_ROWS EOF` 가 그 줄바꿈에서 레코드를
  둘로 쪼갠다 → 한 노드는 필드가 밀려 `gate:""`가 되고, 다른 조각은 dep id를 `id`로
  오인한 **유령 노드**가 된다. `ready==true`가 잘못 늘어 `readyCount`도 틀린다.

관측: active=workflows-coSherpa/goals/3-search.md 상태에서 005가 `gate:""`로, dep "004"가 별도 노드로
튀어나오고 `readyCount`가 1이 아니라 2로 나왔다.

## Options / Recommendation

- (A) **Recommended** — deps를 레코드에 넣기 전에 한 줄로 평탄화. 예: L87 파이프 끝에
  `| tr '\n' ' '` 를 더하고 trailing space를 정리, 또는 L103 직전에
  `deps="$(printf '%s' "$deps" | tr '\n' ' ')"`. 소비처(L90, L117, L131의 `for d in $deps`)는
  공백 구분도 그대로 처리하므로 안전.
- (B) FEATURE_ROWS 구분자를 줄바꿈이 아닌 NUL/제어문자로 바꾼다 — blast radius 큼, defer.

## Acceptance signal

`workflows-coSherpa/dashboard/engines/roadmap-selftest.sh`의 deps 그룹에 **의존성 2개 이상인 픽스처 이슈**를
추가하고, 그 노드가 단일 레코드로 `deps:["001","004"]`를 갖고 유령 노드가 없으며
`readyCount`가 정확함을 단언. 오늘은 그런 픽스처가 없어 self-test가 못 잡았다(2-dep
회귀 미커버) → red→green 대상.

## Migration plan

1. RED: self-test deps 그룹에 2-dep 픽스처 추가 → 현재 생성기에서 실패 확인.
2. GREEN: 위 (A) 평탄화 적용.
3. data-schema.md `## 적합성 검증`에 "2-dep 레코드 무결성" 한 줄 추가(스펙↔테스트 정합).
