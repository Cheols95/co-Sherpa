# workflows-coSherpa/docs/prd/

`/to-prd` 산출 PRD를 둔다. 기본 파일명 `PRD.md`. `PRD.md`는 기능별로 새 파일을 늘리지 않는 단일 누적
문서다. `/freeze`는 기존 frozen intent를 삭제하거나 약화하지 않고 이번 기능의 의도 섹션만 추가/갱신한다.
Phase 1에서 작성하고, `/build workflows-coSherpa/docs/prd/PRD.md`가 이를 읽어
`workflows-coSherpa/goals/<n>-*` 계약으로 변환한 뒤 곧바로 gate green 구현 루프에 들어간다.
