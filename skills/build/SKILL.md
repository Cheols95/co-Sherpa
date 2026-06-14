---
name: build
description: "FCG(findings-cycles-goals) 목표 엔진. goals/ 미션 스택을 .gates.sh로 기계 검증하며 게이트를 green으로 만든다. (1) 'goal 돌려줘', 'build', '게이트 통과시켜줘', 'active goal 완수' 요청, (2) docs/issues/*.md 또는 docs/prd/PRD.md를 goals/<n>-* 실행계약으로 변환할 때, (3) 'cycles/<파일>.md 완수까지 작업' 처럼 cycle driver 문서를 받아 무한 루프로 실행할 때 활성화. goal 파일과 cycle driver 둘 다 입력으로 받는다."
---

# build — FCG 목표 엔진

`goals/`(미션 스택)를 `.gates.sh`로 기계 검증하며 완수하는 엔진. **goal 파일** 또는 **cycle driver 파일**을 입력으로 받아 같은 FCG 루프를 돌린다. 단일 에이전트(Claude 또는 GPT/Codex)가 직접 실행한다 — 멀티 에이전트 팀 불필요.

> 상세 규약은 프로젝트의 `goals/AGENTS.md`, `cycles/AGENTS.md`, `docs/goal-design.md`, `guidelines/goal-iteration.md`에 있다. 이 스킬은 그 진입점이다.

## 모드 판별

| 입력 | 모드 |
|---|---|
| 없음 / `goals/<n>-*.md` | **A. 게이트 루프** — active goal을 green으로 |
| `docs/issues/*.md` 또는 `docs/prd/PRD.md` | **B. 변환** — 슬라이스/PRD → `goals/<n>-*` 3파일 계약 생성 |
| `cycles/<파일>.md` | **C. 사이클 실행** — loop-driver 문서대로 findings 소진까지 |

> **경로 없는 변환/사이클 의도는 되묻는다.** 입력이 모드를 정한다. "변환해줘"·
> "사이클 돌려줘"처럼 B(변환)/C(사이클) 의도인데 경로(`docs/issues/*.md`·
> `docs/prd/PRD.md`·`cycles/<파일>.md`)가 빠지면, 모드 A로 빠지지 말고 어떤
> 입력인지 되묻는다. (자연어로 트리거하는 Codex에서 특히 중요.)

---

## 모드 A — 게이트 루프 (기본)

항상 진단부터:
```bash
bash scripts/diagnose.sh        # git/active-goal/열린 finding/blocker (read-only)
```
그 다음 TDD 루프:
```bash
bash scripts/active-check.sh    # active goal gate + rigor sweep. green이면 자동 completion-check
bash scripts/completion-check.sh # 전체 goal gate 병렬, 첫 실패를 .state/active-goal에 기록
bash scripts/update-state.sh    # docs/state/{progress,next-task}.md 재생성
```

**규율(Rigor Rules)**
1. 새 세션·수정 시작 시 반드시 `diagnose.sh`로 active-goal 방향을 먼저 확인.
2. `active-check.sh`가 green이 될 때까지 코드를 RED→GREEN으로 수정. green이면 엔진이 자동으로 다음 goal로 전진.
3. 게이트는 직접 고치지 않는다 — 코드를 고쳐 게이트를 통과시킨다. (게이트는 불변 계약)
4. **RISKY 마감 리뷰**: goal frontmatter가 `risk: RISKY`면 green 후 전진 전에 비저자 서브에이전트 1회가
   goal `.md` 미션 ↔ 이 goal의 라벨 커밋 raw diff를 대조한다(요약 전달 금지 — 앵커링 방지). 발견은
   finding으로 큐잉할 뿐 게이트 판정을 막지 않는다. 작업 중 행위 표면이 선언보다 크면 그 자리에서
   RISKY로 **상향만** 허용(하향은 사용자 승인). 상세: 프로젝트 `goals/AGENTS.md` §Risk tier.

---

## 모드 B — 변환 (Phase 1 → 2 다리)

`docs/issues/*.md`(또는 `docs/prd/PRD.md`)를 읽어 각 수직 슬라이스를 **3파일 계약**으로 만든다(`goals/AGENTS.md` 준수):
```
goals/<n>-<name>.md            # Mission: 'done' 조건을 prose로 (universal claim 사용 시 enumerate)
goals/<n>-<name>.gates.sh      # 기계 검증 (chmod +x). "every X"면 source of truth에서 X를 enumerate
goals/<n>-<name>.next-task.sh  # 다음 액션 힌트 (chmod +x, 절대 gate 아님)
```
- **변환 전 1회 참조**: `goals/EXAMPLE.md`(이슈→3파일 모범 변환 정답지, 안티패턴 주석 포함)가 프로젝트에 있으면 먼저 읽는다. 구버전 템플릿엔 없을 수 있다 — 그러면 `goals/AGENTS.md` 규약만으로 진행.
- **첫 변환**이면 `goals/0-example.*` 교육용 placeholder triplet을 제거한다(`goals/AGENTS.md` 부트스트랩 규약 — 안 지우면 예제가 실제 체인에 영구 잔존). `goals/EXAMPLE.md`는 goal이 아니라 문서이므로 **삭제 대상이 아니다**.
- **risk 운반**: 이슈 frontmatter `risk: RISKY|MECHANICAL|NONE`을 goal `.md` frontmatter로 그대로 옮긴다.
  이슈에 없으면 변환 시 휴리스틱으로 판정(프로젝트 `AGENTS.md` §Agent-skills configuration) — **미지정은
  MECHANICAL이 아니라 미판정**이며, 행위 표면이 보이면 강한 검증 쪽으로 기운다.
- **횡단 불변식 = `_meta` 세트 — 첫 변환에서 이빨을 켠다 (자동, 사용자 개입 불필요).**
  `goals/_meta.gates.sh`의 `META_CHECKS`는 비어 출하되어 "vacuously pass"(아무것도 검증 안 함)다.
  첫 모드 B 변환에서 — `0-example` 삭제와 같은 시점에 — **반드시**:
  (1) 스택 감지(`package.json`·`pyproject.toml`·`Cargo.toml`·`go.mod`·`*.csproj` 등 설정 파일),
  (2) 그 스택의 lint·typecheck·test·build 실제 명령을 `META_CHECKS`에 `"label::command"`로 채운다
  (`_meta.gates.sh` 상단 주석의 스택별 예시 참조 — 해당 없는 축은 생략),
  (3) `GATE_INPUTS`를 소스·테스트·설정으로 확장한다(자기참조 3줄 유지 — 코드 변경 시 캐시 무효화),
  (4) 서비스가 뜨면 `scripts/smoke.sh`(부팅→헬스체크→2xx→teardown)를 만든다(=`_meta`에 런타임 스모크 자동 배선),
  (5) `bash goals/_meta.gates.sh`를 1회 실행해 명령이 실제로 돌고 통과하는지 확인한다(wiring 오류 조기 발견).
  안 채우면 회귀 안전망이 빈 총인 채 남는다 — `diagnose.sh`가 매 진단에서 경고한다.
- 각 gate는 `scripts/_gate-cache.sh`를 source하고 `GATE_INPUTS`를 선언하며, 끝에 `check-gate-rigor.sh`로 자기 `.md` 정합성을 검사.
- **게이트 ≠ convention police**: 테스트·타입체커·커버리지가 더 정확히 잡는 것은 게이트에 하드코딩하지 않는다. "이 불변식이 깨지면 어떤 테스트가 red가 되나?" → 된다면 그 테스트가 소유, 게이트에서 제거.
- **red-first 위생검사 (변환 직후 1회)**: 3파일을 다 만든 직후, 구현 전 코드에서
  `bash scripts/red-first-check.sh`로 새 goal 게이트가 **전부 red인지** 확인한다. 구현 전
  green인 게이트는 아무것도 안 검사하는 빈 게이트(`exit 0`·tautology) — 그 자리에서 고친다.
  (근거: 프로젝트 `AGENTS.md` §Gate validity. check-gate-rigor가 못 잡는 빈-게이트 클래스를 잡는다.)
- **graph-lint (변환 후)**: 이슈 의존성을 옮겼으면 `bash scripts/issues-graph-check.sh`로
  순환·dangling이 없는지 확인(`/freeze`가 이미 봉인 시 강제하지만, 직접 변환 경로의 안전선).

---

## 모드 C — 사이클 실행 (무한 루프)

`cycles/<파일>.md`는 한 세션 **loop-driver 프롬프트**다. 그 문서의 알고리즘대로:
1. 체인 상태 확인 → 미완 goal 마무리 → 다음 finding.
2. 각 finding: 읽기 → promote(goal로)·직접처리 결정 → TDD 실행 → 코드 대조 검증 → frontmatter/Resolution 갱신.
3. **무인 운영 규율**: 무진전이면 사다리(맥락 보강 → 접근 전환 → blocker 기록 후 다음 target)를 밟고 **절대 조기 종료 금지** — 모든 in-scope가 resolved/partial이고 체인이 green일 때만 종료. 사다리 단계·횟수는 `guidelines/goal-iteration.md` §When You Are Stuck.
4. out-of-scope로 명시된 항목은 발견해도 건드리지 않는다.
5. **종료 보고에 `/spec-sync` 1회 권고를 포함**한다 — 사이클 직후가 계약(docs/spec) 정합의 최적 시점(근거: `cycles/AGENTS.md` §"A cycle document MUST contain" — Termination/verification 항).

---

## 출력 규율 (모든 모드, 특히 루프)

말하는 순간은 정확히 셋: **(a) 진짜 필요한 질문, (b) 결과/요약 보고, (c) blocker.** 그 사이의 과정
내레이션("이제 ~를 읽겠습니다", "now I'll…")은 금지 — 도구 호출은 이미 화면에 보이므로 순수 낭비다.
사용자 대면 문장에 내부 용어를 흘리지 말고, 사용자의 언어로 쓴다. 출력 토큰은 직접 비용이다.

---

## 환경변수 (선택)
`GATES_CONCURRENCY`(기본 4) · `GATES_SKIP_DEEP`(빠른 iteration, completion-check 기본 1) · `GATES_NO_CACHE` · `GATES_SKIP_META`.

`.state/`(active-goal 포인터 + gate 캐시)는 런타임 생성물이며 **gitignore 대상**이다.
