# mini-commerce-ops-scenario.md - Mini Commerce Ops E2E scenario

## 기본 정보

검증용 scratch 프로젝트 이름은 `Mini Commerce Ops`다. 실제 E2E 실행 시 프로젝트 폴더는 repo root의 `e2e_shop_demo/`에 생성한다. 앱은 정적 HTML/CSS/JS로 만들며, 프레임워크나 빌드 도구를 추가하지 않는다. 외부 API, DB, auth provider, payment provider를 사용하지 않고 모든 상태는 브라우저 메모리 또는 단순 로컬 상태로 구현한다.

>> 복잡한 기술 스택을 검증하는 것이 아니라, co-Sherpa workflow가 실제 기능 개발 흐름을 잘 이끄는지 검증하는 것이 목적이다.

## 필수 파일 예시

E2E 구현 결과물은 최소 다음 파일을 가진다.

```text
e2e_shop_demo/index.html
e2e_shop_demo/styles.css
e2e_shop_demo/script.js
e2e_shop_demo/AGENTS.md
e2e_shop_demo/CONTEXT.md
e2e_shop_demo/workflows-coSherpa/
```

필요하면 테스트 로그, roadmap, handoff 문서를 추가할 수 있다.

>> 이 파일 목록은 full E2E가 최종 산출물을 확인할 때 쓰는 최소 기준이다.

## 사용자 역할

임시 customer login:

```text
customer@example.com
```

임시 admin login:

```text
admin@example.com
```

비밀번호는 요구하지 않는다. 이메일 입력만으로 role을 판단한다.

역할 규칙:

- customer는 상품 조회, 장바구니 조작, 쿠폰 적용, checkout을 할 수 있다.
- admin은 주문 목록을 보고 주문 상태를 변경할 수 있다.
- 알 수 없는 이메일은 로그인 실패 상태를 보여준다.

>> 실제 보안을 검증하는 것이 아니라, role에 따라 기능 표면이 달라지는 workflow를 만들기 위한 장치다.

## 상품 카탈로그

더미 상품 3개를 사용한다.

```text
SKU: NOTE-001
Name: Field Notes Pack
Price: 12000
Initial stock: 5
```

```text
SKU: MUG-002
Name: Trail Mug
Price: 18000
Initial stock: 3
```

```text
SKU: CAP-003
Name: Summit Cap
Price: 22000
Initial stock: 0
```

필수 UI:

- 상품명
- SKU
- 가격
- 현재 재고
- 장바구니 담기 버튼
- 품절 상태 표시

필수 규칙:

- 재고가 0인 상품은 품절로 표시한다.
- 품절 상품은 장바구니에 추가할 수 없다.
- 상품 재고는 checkout 전까지는 실제 차감하지 않는다.
- checkout 성공 시 재고를 차감한다.

>> 재고 차감 시점은 `/concept`가 다뤄야 하는 중요한 결정거리다.

## 장바구니

필수 기능:

- 상품 추가
- 상품 삭제
- 수량 증가
- 수량 감소
- 수량 직접 변경 또는 stepper-style 변경
- subtotal 표시
- 재고 초과 수량 방지

필수 규칙:

- 장바구니 수량은 현재 재고를 초과할 수 없다.
- 같은 상품을 여러 번 추가하면 cart line 수량이 증가한다.
- 수량이 0이 되면 cart line을 제거한다.
- 품절 상품은 cart line으로 들어갈 수 없다.

>> 장바구니는 단순해 보여도 재고, checkout, 쿠폰과 연결되므로 통합 검증에 적합하다.

## 쿠폰

지원 쿠폰:

```text
SHERPA10
```

규칙:

- `SHERPA10`은 checkout 1회당 한 번만 적용된다.
- 할인율은 10%다.
- 유효하지 않은 쿠폰은 에러 메시지를 보여준다.
- 같은 checkout에서 같은 쿠폰을 두 번 적용할 수 없다.
- 쿠폰 적용 후 total을 다시 계산한다.
- checkout이 완료되면 다음 주문에서는 쿠폰을 다시 사용할 수 있다.

>> 쿠폰은 “한 번만 적용” 같은 정책 검증이 있어서 spec과 test를 만들기 좋다.

## Checkout

필수 기능:

- customer로 로그인한 상태에서 checkout 가능
- 빈 장바구니 checkout 금지
- 재고 부족 시 checkout 실패
- checkout 성공 시 order 생성
- checkout 성공 시 재고 차감
- checkout 성공 시 cart 비우기
- checkout 성공 시 order 최초 상태는 `paid`

필수 규칙:

- order id는 사람이 구분할 수 있는 deterministic 값이어야 한다.
- 예: `ORDER-001`, `ORDER-002`
- order에는 line item, total, discount, status, created role 정보가 있어야 한다.
- 결제는 실제 외부 결제가 아니라 simulated payment다.

>> deterministic 값은 같은 순서로 실행하면 예측 가능한 값이다. E2E 검증에서 결과를 확인하기 쉽다.

## 관리자 주문 화면

필수 기능:

- admin login 후 주문 목록 확인
- 주문 상세 정보 확인
- 주문 상태 변경

주문 상태:

```text
paid -> preparing -> shipped
```

필수 규칙:

- 주문은 최초 `paid` 상태로 생성된다.
- admin은 상태를 순서대로만 변경할 수 있다.
- `paid`에서 바로 `shipped`로 건너뛸 수 없다.
- `shipped` 이후에는 더 이상 변경할 수 없다.
- customer는 admin 주문 상태 변경 UI를 볼 수 없다.

>> 주문 상태는 순서 제약이 있어 goal gate와 테스트 기준을 만들기 좋다.

## 화면 상태와 검증 가능한 selector

앱 구현 시 E2E 검증을 쉽게 하기 위해 주요 요소에 stable selector를 둔다.

```text
data-testid="login-email"
data-testid="login-submit"
data-testid="product-card-NOTE-001"
data-testid="add-NOTE-001"
data-testid="cart-line-NOTE-001"
data-testid="cart-qty-NOTE-001"
data-testid="coupon-input"
data-testid="apply-coupon"
data-testid="checkout"
data-testid="order-ORDER-001"
data-testid="admin-orders"
data-testid="advance-order-ORDER-001"
```

>> stable selector는 화면 디자인이 바뀌어도 검증 코드가 같은 요소를 찾을 수 있게 해주는 이름표다.

## co-Sherpa 검증에 적합한 이유

이 시나리오는 다음 이유로 co-Sherpa 검증에 적합하다.

- `/concept`가 재고 차감 시점, 주문 상태, 로그인 역할, 쿠폰 정책을 질문하게 만들 수 있다.
- `/freeze`가 PRD, spec, issues를 만들 수 있다.
- `/build`가 cart, checkout, orders 같은 vertical slice로 구현할 수 있다.
- `/finding`으로 범위 밖 개선점을 기록할 수 있다.
- `/cycle`로 findings를 묶어 작업 문서를 만들 수 있다.
- `/spec-sync`로 의도적 drift를 만들어 계약 문서와 코드 정합성을 확인할 수 있다.
- `/improve-codebase-architecture`로 cart/checkout/orders 경계를 검토할 수 있다.
- `/roadmap`으로 issue dependency와 status를 HTML로 볼 수 있다.
- `/handoff`로 다음 agent가 이어받을 수 있는 요약을 만들 수 있다.

>> vertical slice는 사용자가 볼 수 있는 작은 기능 단위를 끝까지 구현하는 방식이다.
