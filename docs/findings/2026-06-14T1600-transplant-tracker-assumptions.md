---
title: to-prd/to-issues의 원격 트래커 가정을 로컬 마크다운 현실로 정합
created_at: 2026-06-14T16:00:45Z
resolved: false
priority: P2
related:
  - skills/to-prd/SKILL.md
  - skills/to-issues/SKILL.md
  - docs/agents/issue-tracker.md
  - AGENTS.md
---

# to-prd/to-issues의 원격 트래커 가정을 로컬 마크다운 현실로 정합

## TL;DR
이식된 영어 스킬 `to-prd`/`to-issues`가 원격 "issue tracker"·트리아지 라벨·이슈 "comments"를 가정한다 —
이 레포는 로컬 마크다운(PRD = 단일 파일 `docs/prd/PRD.md`, 이슈에 comments 없음). AGENTS 재매핑으로
작동은 복구되나 스킬 문구는 GitHub 전제. 두 스킬은 영문 유지(2026-06-14 결정)이므로 문구만 패치.

## Body
- `skills/to-prd/SKILL.md:18` — *"publish it to the project issue tracker. Apply the `ready-for-agent`
  triage label"*. 그러나 PRD는 `docs/prd/PRD.md` 단일 파일이고, 트리아지 라벨은 이슈용(PRD 아님 —
  category error).
- `skills/to-issues/SKILL.md:16` — *"fetch it from the issue tracker … read its full body and
  comments"*, `:54` *"publish a new issue to the issue tracker"*. 로컬 마크다운엔 comments가 없다.
- **완화책 존재**(작동은 함): 둘 다 *"tracker should have been provided … else read AGENTS.md"*
  (`to-prd:8`/`to-issues:10`) + `docs/agents/issue-tracker.md` 재매핑.

## Options / Recommendation
- (A) **Recommended** — 각 스킬 상단에 1줄(영문): *"In this repo: tracker = `docs/issues/*.md`; PRD =
  single file `docs/prd/PRD.md`; no remote UI / comments / PRD label."* — 거짓 문구를 무효화.
- (B) 거짓 문구 2개(triage label on PRD; issue "comments")를 직접 수정.

## Acceptance signal
`to-prd`/`to-issues`에 로컬 현실과 모순되는 GitHub 전제 문구가 없다(또는 상단 1줄로 무효화됨).
