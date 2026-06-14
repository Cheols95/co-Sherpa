---
name: improve-codebase-architecture
description: "코드베이스의 deepening(얕은 모듈을 깊게 만들기) 기회를 CONTEXT.md의 도메인 언어와 docs/adr/의 결정에 비추어 찾는다. 아키텍처 개선, 리팩토링 기회 발굴, 강결합 모듈 통합, 또는 코드베이스를 더 테스트 가능·AI-탐색 가능하게 만들고 싶을 때 활성화."
---

# improve-codebase-architecture — 코드베이스 아키텍처 개선

아키텍처 마찰과 **deepening 기회** — 얕은(shallow) 모듈을 깊은(deep) 모듈로 바꾸는 리팩토링 — 를 드러낸다.
목표는 테스트 가능성과 AI-탐색 가능성이다.

## 용어집 (Glossary)

모든 제안에서 이 용어를 정확히 쓴다. 일관된 언어가 핵심이다 — "component"·"service"·"API"·"boundary"로
흘러가지 마라. **[LANGUAGE.md](LANGUAGE.md)가 전체 용어집·원칙을 소유한다**(Module, Interface,
Implementation, Adapter, interface-is-the-test-surface 규칙, one-vs-two-adapter 규칙…). 아래 Process가
가장 많이 기대는 용어:

- **Depth(깊이)** — 인터페이스에서의 레버리지: 작은 인터페이스 뒤에 많은 동작. **Deep** = 높은 레버리지.
  **Shallow** = 인터페이스가 구현만큼 복잡한 상태.
- **Seam(이음매)** — 인터페이스가 사는 곳; 제자리 수정 없이 동작을 바꿀 수 있는 지점. ("boundary" 말고 이걸 쓴다.)
- **Leverage / Locality** — 깊이가 사는 것: 호출자에겐 leverage(레버리지), 유지보수자에겐 locality(변경·버그·
  지식이 한곳에 집중).
- **Deletion test(삭제 테스트)** — 모듈을 지운다고 상상한다: 복잡도가 사라지면 → 통과만 시키던 pass-through였다;
  복잡도가 N개 호출자로 퍼지면 → 제값을 하고 있었다.

이 스킬은 프로젝트 도메인 모델의 _정보를 받는다_. 도메인 언어가 좋은 seam에 이름을 주고, ADR은 이 스킬이
다시 따지지 말아야 할 결정을 기록한다.

## 절차 (Process)

### 1. 탐색 (Explore)

먼저 건드리는 영역의 프로젝트 도메인 용어집과 ADR을 읽는다.

그다음 Agent 도구를 `subagent_type=Explore`로 써서 코드베이스를 걷는다. 경직된 휴리스틱을 따르지 말고 —
유기적으로 탐색하며 마찰을 느끼는 곳을 적는다:

- 한 개념을 이해하는 데 작은 모듈 여러 개를 오가야 하는 곳은?
- 모듈이 **shallow**한 곳 — 인터페이스가 구현만큼 복잡한 곳은?
- 순수 함수가 테스트 가능성만으로 추출됐지만, 진짜 버그는 그게 *호출되는 방식*에 숨은(=locality 없는) 곳은?
- 강결합 모듈이 seam을 넘어 새는 곳은?
- 현재 인터페이스로는 테스트가 안 되거나 어려운 곳은?

shallow 의심 대상엔 **삭제 테스트**를 적용하라: 지우면 복잡도가 *집중*되나, 그냥 *이동*하나? "집중된다"가
원하는 신호다.

### 2. 후보를 HTML 리포트로 제시

레포에 아무것도 안 남게 OS 임시 디렉토리에 자기완결 HTML 파일을 쓴다. 임시 디렉토리는 `$TMPDIR`에서
해결하고 `/tmp`(Windows는 `%TEMP%`)로 폴백, `<tmpdir>/architecture-review-<timestamp>.html`에 써서 매
실행마다 새 파일을 얻는다. 사용자에게 열어준다 — Linux `xdg-open`, macOS `open`, Windows `start` — 그리고
절대 경로를 알려준다.

리포트는 레이아웃·스타일에 **Tailwind(CDN)**, 그래프/흐름/시퀀스가 구조를 확실히 전달하는 곳엔 다이어그램으로
**Mermaid(CDN)**를 쓴다. Mermaid와 손으로 짠 CSS/SVG 비주얼을 섞어라 — 관계가 그래프 모양(호출 그래프,
의존성, 시퀀스)이면 Mermaid, 더 편집적인 것(질량 다이어그램, 단면도, 붕괴 애니메이션)이면 손으로 짠 div/SVG.
각 후보는 **before/after 시각화**를 갖는다. 시각적으로 하라.

각 후보는 카드로 렌더하되 같은 템플릿:

- **Files** — 관련된 파일/모듈
- **Problem** — 현재 아키텍처가 마찰을 일으키는 이유
- **Solution** — 무엇이 바뀌는지 평이한 한국어 설명
- **Benefits** — locality·leverage 관점, 그리고 테스트가 어떻게 나아지는지
- **Before / After 다이어그램** — 나란히, 직접 그려서, shallow함과 deepening을 보여줌
- **Recommendation strength** — `Strong`·`Worth exploring`·`Speculative` 중 하나, 배지로

리포트 끝에 **Top recommendation** 섹션: 어느 후보를 먼저 다룰지와 그 이유.

**도메인엔 CONTEXT.md 용어를, 아키텍처엔 [LANGUAGE.md](LANGUAGE.md) 용어를 쓴다.** `CONTEXT.md`가
"Order"를 정의하면 "the FooBarHandler"도 "the Order service"도 아닌 "Order intake 모듈"이라 말하라.

**ADR 충돌**: 후보가 기존 ADR과 모순되면, 마찰이 ADR을 재검토할 만큼 진짜일 때만 드러낸다. 카드에 또렷이
표시하라(예: 경고 콜아웃 _"ADR-0007과 모순 — 그래도 재론할 가치가 있는 이유는…"_). ADR이 금지하는 모든
이론적 리팩토링을 나열하지 마라.

전체 HTML 스캐폴드·다이어그램 패턴·스타일 지침은 [HTML-REPORT.md](HTML-REPORT.md) 참조.

아직 인터페이스를 제안하지 마라. 파일을 쓴 뒤 사용자에게 묻는다: "이 중 어느 것을 탐색하고 싶으세요?"

### 3. Grilling 루프

사용자가 후보를 고르면 grilling 대화로 들어간다. 함께 설계 트리를 걷는다 — 제약, 의존성, 깊어진 모듈의
형태, seam 뒤에 무엇이 있는지, 어떤 테스트가 살아남는지.

의존성 분류별 deepening 실행법·seam 규율·"replace, don't layer" 테스트 전략은 [DEEPENING.md](DEEPENING.md)를 따른다.

부수효과는 결정이 굳을 때 인라인으로 일어난다:

- **깊어진 모듈을 `CONTEXT.md`에 없는 개념으로 명명?** 그 용어를 `CONTEXT.md`에 추가한다 — `/grill`과
  같은 규율([CONTEXT-FORMAT.md](../grill/CONTEXT-FORMAT.md) 참조). 파일이 없으면 lazily 생성.
- **대화 중 모호한 용어를 날카롭게?** 그 자리에서 `CONTEXT.md` 갱신.
- **사용자가 load-bearing 근거로 후보를 거부?** ADR을 제안하되 이렇게 틀 짓는다: _"미래 아키텍처 리뷰가
  같은 걸 다시 제안 안 하게 ADR로 기록할까요?"_ 미래 탐색자가 같은 제안을 피하려 실제로 필요로 할 근거일
  때만 제안하라 — 일시적("지금은 가치 없음")이거나 자명한 이유는 건너뛴다. [ADR-FORMAT.md](../grill/ADR-FORMAT.md) 참조.
- **깊어진 모듈의 대안 인터페이스를 탐색?** [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md) 참조.
