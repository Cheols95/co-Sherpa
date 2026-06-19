# workflows-coSherpa/docs/design/AGENTS.md — Phase 1 concept 규칙 (정본)

> 루트 `AGENTS.md`에서 이전한 **Phase 1 elicitation** 규칙의 단일 출처. `/concept`·`/freeze`가 작업 전
> 반드시 읽는다. 체크리스트의 *형식·표기·닫힘 상태·예시*는 같은 폴더 `README.md`가 소유한다
> (역할 분담: 여기 = 규칙, `README.md` = 형식).

## Sequence

`/concept` (결정표면을 `workflows-coSherpa/docs/design/checklist.md`에 정산 — 모든 슬롯이 닫힐 때까지) → `/freeze` (유일한
인간 승인점 — 닫힌 기능을 to-prd → spec → to-issues → graph-lint로 sealed 봉인) → `/build`. Freeze는
**기능 단위**(tracer-bullet): 기능 A를 봉인하는 동안 기능 C는 계속 concept 진행 가능.

## 규칙

- **Start by shaping the idea, not by writing issues.** On concept entry, first ORIENT around the
  project character: purpose, users, success signal, scale, hard constraints, and whether existing
  code already constrains the answer. Then DECOMPOSE the input into domain concepts, user actions,
  data, policy/authorization, failures/edges, technical choices, external systems, and out-of-scope.
  A thin input raises the bar: a one-line idea means more hidden decisions, not fewer.
- **Surface load-bearing choices before freezing the spec.** Persistence, delivery shape
  (service / library / CLI / UI), and stack are decisions the whole plan rests on — state them to
  the user **explicitly, with the trade-off**, never silently default. A silently-defaulted
  load-bearing choice traps a user who didn't know to object; they discover the wrong one only at
  build time. `/freeze` will not seal a contract while such a choice is unresolved.
- **Ask in plain words, encode in precise rules.** With a non-developer, translate jargon into the
  decision behind it: not "is this an invariant?" but "if this changes, must something else change
  too?"; not "what's the authorization model?" but "who may do this, and who must be blocked?" Then
  translate the plain answer back into the precise contract term.
- **Account the decision surface — the observable exit bar for concept.** Before freezing, name the
  entities (a manifest), then walk four lenses over each entity and colliding pair to enumerate the
  load-bearing decisions the concept is *obligated* to answer: **STRUCTURAL** (cardinality/
  composition/identity), **BEHAVIORAL** (lifecycle/concurrency/policy/edges), **TECHNICAL**
  (persistence/interface/consistency), **CONTRACT** (status·enum *sets*/uniqueness/output keys).
  Every slot must end **grounded** (the user said it, or it follows from what they said),
  **asked-and-answered**, **deferred-tunable** (a default inside a settled mechanism, marked
  tunable), **experiment-pending** (a load-bearing choice a prototype will settle — parked, not
  guessed), or **N/A — covered** (a load-bearing lens deliberately excluded, with the covering
  argument named — e.g. "concurrency: N/A — single user"). These are the *semantic* exit states;
  their checklist **notation** (`[x]` / `[~]` / `[>]` / `[-]`) is owned by `README.md`
  (the single source for the symbols). Enumerate exhaustively, ask minimally — never ask what is
  derivable. concept ends when no **un-grounded** slot survives — not when it "feels like enough".
- **Track presence, not optimism.** A slot that is merely mentioned is not closed; it is closed only
  when rules exist. "Payment exists" is presence; "cancelled payment is voided/refunded/held under
  these conditions" is coverage. For each closed slot, name the user-model basis: goal, value,
  constraint, or domain fact. Main domain concepts must answer: what it is, what it does, what it
  cannot do, and how it ends.
- **Filter candidate questions through a grounds-gate.** A question — or a new checklist item — may
  reach the user only when it can state three things: its **site** (which entity/slot), **why** the
  material at hand doesn't already settle it, and the **consequence** of guessing wrong. **The *why*
  is the termination engine:** actively argue that spec/code/harness/convention does *not* already
  cover it — "might be covered" is not enough; a loose *why* lets the surface grow without bound
  (unbounded concept work moves into the file). A candidate that can't state all three is noise — drop it;
  don't spray "have you considered X?". The gate filters noise only — it is never a license to drop a
  load-bearing slot by under-arguing. When genuinely unsure whether a slot is load-bearing, ask: one
  question costs a beat, an un-surfaced decision costs a wrong build.
- **Ask as a design tree.** Parent decisions precede child decisions: user type before authorization,
  authorization before failure policy, failure policy before test seam. Ask one independent decision
  at a time. Every question carries a recommended answer, the reason for the recommendation, and a
  visible way for the user to reject or replace it; domain multiple-choice questions must include an
  open option.
- **Demote incoming documents to material — track presence, not coverage.** A spec/plan/notes file
  brought from elsewhere enters as challengeable material, not ground truth: a document's existence
  is no evidence of the concept conversation behind it. While accounting the surface, distinguish a
  slot the input merely *mentions* from one it *states with rules* — "touched" is not "covered",
  and only stated-with-rules counts toward `grounded`. Differences between sources (doc ↔ spoken ↔
  code) become questions, never silent picks.
- **Pre-freeze intent-audit (independent, two directions).** Right before `/freeze` seals the
  contract, dispatch one subagent that did **not** author the plan; it reads the dialogue + the
  decision surface and runs **both** audits: **(a) disposition** — is each `[x]`/`deferred` slot
  defensible from the dialogue, or was a guess rubber-stamped as grounded? (hunts over-claiming);
  **(b) residual-enumeration** — independently re-walk the four lenses over the entity manifest and
  colliding pairs to find any obligation-slot *nobody enumerated* (hunts under-listing). **Without
  (b) the closure condition is forgeable** — closure is defined on the checklist's own contents,
  which the agent controls, so simply omitting a checkbox would make a feature "closed". Each finding
  is closed by asking the user — never patched silently into a document; if closing one opens new
  edges, re-walk only the touched slots once, then escalate to the user (not an open loop). No
  subagent tooling (e.g. a Codex session) → run both as an explicit self-review pass and surface the
  list. This audit is **no license for shallow concept work** — a finding here means the dialogue was
  closed too early.
- **Run a fidelity pass before declaring ready.** Checklist, `CONTEXT.md`, and ADR/rationale text
  must neither add claims the user did not decide nor weaken decisions the user did make. If the
  document is stronger or weaker than the conversation, fix it before declaring `/freeze ready`.
- **Freeze is one-way.** Once `/freeze` seals a feature, a *new* concept idea about it goes to
  `workflows-coSherpa/docs/findings/` (not a checklist re-open); only a *fundamental error in a frozen decision* re-opens
  Phase 1, and only with explicit user approval. Routing: simple addition / conflict → findings; the
  frozen decision itself is wrong → `/concept` re-open.
