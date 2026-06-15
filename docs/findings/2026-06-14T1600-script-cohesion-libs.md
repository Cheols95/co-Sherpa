---
title: 스크립트 열거/파싱 로직 라이브러리 추출 (_goals-lib)
created_at: 2026-06-14T16:00:45Z
resolved: true
priority: P2
resolved_by: 68468d2
related:
  - scripts/_goals-lib.sh
  - scripts/_deps-lib.sh
  - scripts/_gate-cache.sh
  - scripts/completion-check.sh
  - scripts/diagnose.sh
  - dashboard/engines/roadmap.sh
---

# 스크립트 열거/파싱 로직 라이브러리 추출 (_goals-lib)

## TL;DR
goal 열거(`_meta`-first 재정렬)·frontmatter 필드 파싱·issue-id 추출이 여러 스크립트에 중복돼 있다.
기존 `_deps-lib.sh`/`_gate-cache.sh` 패턴대로 `scripts/_goals-lib.sh`로 모으면 드리프트 표면이 사라진다.
동작은 정상이라 P2 — 응집도/유지보수 개선.

## Body
- **`_meta`-first goal 열거 블록 중복**: `scripts/completion-check.sh:53-59`(+ prepend 77-79)와
  `scripts/diagnose.sh:57-64`가 거의 동일. 정렬 불변식(`_meta`가 먼저 와야 상태 라벨이 안 틀림)이
  correctness-sensitive라 한쪽만 바뀌면 `_meta` 상태를 오라벨한다.
- **bare `find goals … sort -V`** 반복: `check-gate-rigor.sh:104`, `next-task.sh:44`,
  `update-state.sh:36`, `completion-check.sh:219/293`.
- **frontmatter 첫 블록 필드 awk 중복**: `_deps-lib.sh:26`(`depends:`)와 `diagnose.sh:128`(`resolved:`)
  가 같은 idiom(`---` fence 카운트 후 첫 블록 필드 추출).
- **`issue_id_for()` 우회**: `dashboard/engines/roadmap.sh:64-65`가 `_deps-lib.sh:11-15`의 함수를
  source하고도 인라인 `${base%%-*}`로 재구현.
- **active-goal 포인터 읽기** 6곳(active-check/check-gate-rigor/completion-check/diagnose/next-task/
  update-state) — trivial(2~3줄)이라 최저 우선.

## Options / Recommendation
- (A) **Recommended** — `scripts/_goals-lib.sh` 신설: `list_goals_meta_first()`·`list_goals()`·
  `frontmatter_field <file> <key>` 제공. `roadmap.sh`는 `issue_id_for` 호출로 교체.
- (B) 그대로 둠 — 동작은 정상이나 드리프트 위험 잔존.

## Acceptance signal
중복 블록이 lib 한 곳으로 모이고, completion-check/diagnose의 출력(goal 상태 라벨)이 변경 전후 **동일**.
`grep -c 'find goals -maxdepth 1' scripts/*.sh`가 lib 외에는 0에 수렴.

## Migration plan
1. `_goals-lib.sh` 추출(열거 + frontmatter helper).
2. completion-check.sh·diagnose.sh부터 교체 → 출력 비교(동일 확인).
3. 나머지 4개 스크립트 + roadmap.sh `issue_id_for` 교체.

## Resolution

**resolved 2026-06-15 (commit `68468d2`).** `scripts/_goals-lib.sh` 신설
(source-only, `_deps-lib`/`_gate-cache`와 동일 패턴) — 헬퍼:
`find_numbered_mds`·`find_goal_mds`·`find_goal_artifacts`·`meta_md_path`·
`read_active_goal`·`frontmatter_field`.

처리:
- **`_meta`-first 열거 중복** (completion-check ↔ diagnose): 각 호출처가
  `meta_md_path` + `find_numbered_mds`로 분리 호출. completion-check의
  `GATES_SKIP_META` 분기와 diagnose의 무조건 prepend를 **각각 보존**.
- **bare `find … sort -V` 7곳**: `find_numbered_mds`/`find_goal_mds`로 교체
  (completion-check 59/219/293, diagnose 63, check-gate-rigor 104, next-task 44,
  update-state 36).
- **active-goal 읽기 6곳**: `read_active_goal`로 교체.
- **roadmap.sh `issue_id_for` 우회**: 인라인 `${base%%-*}` → `issue_id_for "$f"`.
- **frontmatter awk idiom**: 제네릭 `frontmatter_field`를 lib에 두고
  `diagnose.sh:128`(resolved)이 사용.

**검증**: 각 헬퍼가 원본 인라인식과 byte-identical(unit-equivalence diff 0),
6개 스크립트 출력이 변경 전후 동일(diagnose·completion-check은
`GATES_SKIP_META=1` 포함), `roadmap-selftest.sh` green, `bash -n` 전부 통과.

**의도적으로 남긴 것 (중복 아님 — 각 1회·고유 술어)**:
- `diagnose.sh:95` `real_goal` (`! -name '0-example.md'` — 부트스트랩 전용).
- `template-clean-check.sh:39` (goals/ 전체 파일 — 템플릿 위생, goal 열거 아님).
- `_deps-lib.sh:26` `parse_issue_deps` (depends + 산문 폴백 + id 필터 —
  graph-lint 게이트가 의존. `frontmatter_field`로 합치면 issues-graph-check·
  roadmap이 `_goals-lib`에 transitively 의존하게 되므로 결합 회피 위해 미변경).

→ Acceptance: 중복 열거 블록 0(7→0), 남은 `find goals -maxdepth 1`은 위 2개
고유 술어뿐. completion-check/diagnose 출력 동일.
