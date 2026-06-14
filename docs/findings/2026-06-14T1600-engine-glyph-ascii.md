---
title: 엔진 스크립트 유니코드 글리프 → ASCII 표준화 (cp949 손상 방지)
created_at: 2026-06-14T16:00:45Z
resolved: true
priority: P1
status_notes: |
  CLOSED 2026-06-15 — 4개 엔진 스크립트(completion-check·active-check·diagnose·check-gate-rigor)의
  글리프(✓✗⚙🎉⚠▷→)와 em/en dash·ellipsis를 ASCII([OK]/[FAIL]/[ACTIVE]/[DONE]/[WARN]/>/--/...)로
  치환. 비-ASCII grep 0 + bash -n 통과 확인. (workflow v1.5 후속 커밋)
related:
  - scripts/completion-check.sh
  - scripts/active-check.sh
  - scripts/diagnose.sh
  - scripts/check-gate-rigor.sh
---

# 엔진 스크립트 유니코드 글리프 → ASCII 표준화 (cp949 손상 방지)

## TL;DR
4개 FCG 엔진 스크립트가 `✓ ✗ ⚙ 🎉 ⚠ ▷` 글리프를 출력한다. Codex가 Windows cp949로 재저장하면 이
기호들이 `?`로 깨지는 알려진 실패모드가 있다. 같은 스크립트의 주석조차 "ASCII-only … cp949 corruption"을
경고하면서 다른 줄에선 글리프를 쓴다 — 절반만 일관. 실제 손상 이력이 있어 P1.

## Body
- 글리프 출력: `completion-check.sh`(~13개; 예 `🎉 ALL GOALS ACHIEVED`:299, `⚠`:310, `▷`:132),
  `active-check.sh`(~9), `check-gate-rigor.sh`(~10), `diagnose.sh`(~3).
- **자체 모순**: `completion-check.sh:84` 주석 *"ASCII-only message (no glyphs) so a cp949 re-save
  can't corrupt it"* — 그런데 같은 파일 :299 등에서 글리프 사용.
- ASCII-safe 대조군(이미 일관): `issues-graph-check.sh`·`red-first-check.sh`·`template-clean-check.sh`·
  `install-skills.sh`·`update-workflow.sh` 는 `[PASS]/[FAIL]/[OK]/[WARN]`만 쓴다.

## Options / Recommendation
- (A) **Recommended** — 전 엔진 스크립트를 `[PASS]/[FAIL]/[OK]/[WARN]/[ACTIVE]/[DONE]` ASCII 어휘로
  통일(이미 절반이 이 어휘). Codex 재저장에 면역.
- (B) 글리프 유지 + 인코딩 강제 — 환경 의존적이라 비권장.

## Acceptance signal
`grep -rnP '[^\x00-\x7F]' scripts/*.sh` 가 (의도적 비-ASCII 주석 외) 0줄. 또는 위 4개 파일의 글리프 0.

## Migration plan
Codex가 가장 자주 만지는 순서로: completion-check → active-check → diagnose → check-gate-rigor.
(근본원인은 사용자 메모리의 cp949 글리프 손상 패턴과 동일.)
