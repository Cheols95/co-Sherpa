# Triage labels (for engineering skills)

> Single source of truth: **`AGENTS.md` → "Agent-skills configuration" → "Triage roles"**
> (auto-loaded each session). This file is a pointer + ready path-slot for the `triage` skill
> when it is installed (currently deferred).

Triage state lives in a `Status:` line near the top of each `docs/issues/<NNN>-*.md` file.

Canonical role → label string (identical here; no remapping):

| Canonical role   | Label string     | Meaning |
|------------------|------------------|---------|
| needs-triage     | `needs-triage`   | new, not yet evaluated |
| needs-info       | `needs-info`     | blocked on a question |
| ready-for-agent  | `ready-for-agent`| scoped enough for the FCG loop / GPT |
| ready-for-human  | `ready-for-human`| needs a human decision/action |
| wontfix          | `wontfix`        | closed, will not be done |

Category roles: `bug`, `enhancement`.
