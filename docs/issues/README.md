# docs/issues/

`/to-issues`(issue-tracker=local) 산출 **수직 슬라이스 목록**을 둔다. 파일명 `NNN-<slug>.md` (예: `001-auth-bootstrap.md`).

주의: 여기의 슬라이스는 **목록**이지 FCG goal이 아니다. `/build`이 이를 읽어 `goals/<n>-*.{md,gates.sh,next-task.sh}` 3파일 실행계약으로 변환한다.

## Frontmatter (기계가독 계약 — 판정 기준의 단일 출처는 `AGENTS.md` §Agent-skills configuration)

```yaml
---
depends: [001, 003]   # 차단 이슈 id 인라인 리스트. 없으면 []. 산문 "## Blocked by"와 일치시키되, 어긋나면 frontmatter가 우선
risk: MECHANICAL      # RISKY | MECHANICAL | NONE — RISKY 판정 휴리스틱은 `goals/AGENTS.md` §Risk tier. 비우면 "미판정"(MECHANICAL 아님)
---
```

- `depends:`는 roadmap 대시보드가 직접 읽는다(산문 "Blocked by"는 구버전 이슈용 폴백).
- `risk:`는 `/build` 모드 B가 goal frontmatter로 운반하며, `RISKY` goal은 green 후 닫기 전
  비저자 diff 리뷰 1회를 거친다(`goals/AGENTS.md` §Risk tier).
