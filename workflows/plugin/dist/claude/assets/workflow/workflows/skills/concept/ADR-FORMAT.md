# ADR Format

ADRs live in `workflows/docs/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc.

Create the `workflows/docs/adr/` directory lazily — only when the first ADR is needed.

## One decision per ADR (invariant)

**Each ADR records exactly one decision.** Never bundle multiple decisions into one
file — even when a single concept session produces several. If a session crystallises
three decisions, write three separate ADR files (`0007-…`, `0008-…`, `0009-…`).

Why this matters: when a later decision overrides an earlier one, supersession then
happens at **whole-file granularity** — mark the old ADR superseded and point to the new
one, done. Bundling forces the messy "this file is half-valid, half-superseded" state,
where an agent reading the file can't tell which sections still hold. Atomic ADRs make
that problem structurally impossible.

## Superseding an ADR

When a new decision replaces an old one:

1. The **new** ADR gets its own file as usual.
2. The **old** ADR's frontmatter `Status` becomes `superseded by ADR-NNNN` (pointing to the new one).
3. Add a one-line banner at the very top of the old ADR body: `> ⚠️ Superseded by ADR-NNNN — see that file for the current decision.`
4. (If the project keeps an archive folder, move the superseded file there per the project's `AGENTS.md` convention.)

Never edit the old ADR's decision text to match the new one — an ADR is a historical
record of what was decided *at that time*. You supersede it; you don't rewrite history.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a decision was made and *why* — not in filling out sections.

## Optional sections

Only include these when they add genuine value. Most ADRs won't need them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`) — useful when decisions are revisited
- **Considered Options** — only when the rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects need to be called out

## Numbering

Scan `workflows/docs/adr/` for the highest existing number and increment by one.

## When to offer an ADR

All three of these must be true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If a decision is easy to reverse, skip it — you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library — just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite. These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it — otherwise someone will suggest GraphQL again in six months.
