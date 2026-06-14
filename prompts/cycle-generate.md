# prompts/cycle-generate.md — 사이클 문서 작성 메타 프롬프트

> 이 파일은 새 `cycles/<YYMMDD>-<NN>-<slug>.md` 문서를 **작성하도록**
> Claude/codex 에게 시키는 메타 프롬프트다. 그대로 붙여넣거나 상황에 맞게
> 채워서 쓴다.

---

오케이, 난 이제 에이전트에게 goal 루프를 돌려놓고 자리를 비우고 싶다.

이 goal 루프 기능은 정해진 프롬프트를 **조건이 충족될 때까지 무한 반복**
실행한다. 잘 쓰기 위해 `cycles/` 폴더에 `YYMMDD-NN-<slug>.md` (예:
`cycles/260523-01-overnight-findings-closure.md`) 사이클 구동 문서를
만들어두고, 에이전트에게 `cycles/<file>.md 의 내용을 모두 완수할 때까지
작업해줘` 라고 지시할 것이다. 컨벤션은 `cycles/AGENTS.md` 를 따른다.
이를 위한 사이클 문서를 작성하자.

작성 전 반드시 읽을 것:

- `cycles/AGENTS.md` — 파일명/frontmatter/필수 섹션 규약 (단일 출처)
- `docs/goal-design.md` — harness 설계 (특히 §1.5 minimal gates, §5
  prior-gate 케이스 분류)
- `guidelines/goal-iteration.md` — iteration 프로토콜 (TDD, commit cadence)
- `docs/findings/AGENTS.md` — finding frontmatter schema
- 프로젝트의 커밋 규약

문서에 **반드시** 포함할 섹션과 그 상세 규격은 `cycles/AGENTS.md` §"A cycle
document MUST contain"(단일 출처)를 따른다. 그 목록을 빠짐없이 채우되, 이 메타
프롬프트에서 특히 주의할 점만 아래에 보강한다:

- **frontmatter** — `cycle`/`title`/`authored_at`/`started_at`(공란)/
  `completed_at`(공란)/`status: draft`. (필드 의미: `cycles/AGENTS.md` §Frontmatter.)
- **목표 + Target findings** — 우선순위(P0→P2)·가치/위험으로 tier 를 나누고,
  시작 상태(현재 chain green 여부, 최고 goal 번호, 작업 브랜치)를 명시.
- **루프 알고리즘** — 미완료 goal 마무리 → 다음 미해결 target → 모두 닫히고
  chain green 이면 종료. 무진전 시 사다리(맥락 보강 → 접근 전환 → blocker →
  다음 target, **조기 종료 금지**; `guidelines/goal-iteration.md` §When You Are
  Stuck). promote 한 goal 이 막히면 promotion back-out 으로 chain 을 green 복귀.
- **Goal 화 시 주의점** — minimal gates (rigor + negative universal + 구조
  앵커만), prior-gate 수정은 `docs/goal-design.md` §5 케이스 (a)/(b)/(c) 준수.
- **Reference snapshots** — `kind: snapshot`/`append-only-log` finding 은
  force-close 금지.
- **종료 / 검증** — frontmatter `completed_at`/`status` 갱신 + `learnings.md`
  한 줄 + **`/spec-sync` 1회 권고**(`cycles/AGENTS.md` §"A cycle document
  MUST contain" — Termination/verification 항).
- **출력 규율** — `skills/build/SKILL.md` §출력 규율.

모호하거나 논의할 점 있으면 작성 전에 제안해라.
