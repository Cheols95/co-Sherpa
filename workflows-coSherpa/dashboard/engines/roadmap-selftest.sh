#!/usr/bin/env bash
# Contract tests for roadmap DATA emitted by roadmap.sh.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$ROOT/dashboard/engines/roadmap.sh"
GROUP="${1:-all}"
. "$ROOT/scripts/_portable.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/docs/issues" "$dir/goals" "$dir/.state" "$dir/scripts"
  cat > "$dir/docs/issues/001-base.md" <<'EOF'
# Base
Status: ready-for-agent
Goal: goals/1-base.md

## Acceptance criteria
- [x] base done

## Blocked by
None
EOF
  cat > "$dir/docs/issues/002-active.md" <<'EOF'
# Active
Status: ready-for-agent
Goal: goals/2-active.md

## Acceptance criteria
- [ ] active work

## Blocked by
- 001
EOF
  cat > "$dir/docs/issues/003-ready.md" <<'EOF'
# Ready
Status: ready-for-agent
Goal: goals/3-ready.md

## Acceptance criteria
- [ ] ready work

## Blocked by
- 001
EOF
  cat > "$dir/docs/issues/004-blocked.md" <<'EOF'
# Blocked
Status: ready-for-agent
Goal: goals/4-blocked.md

## Acceptance criteria
- [ ] blocked work

## Blocked by
- 002
EOF
  cat > "$dir/docs/issues/005-dangling.md" <<'EOF'
# Dangling
Status: ready-for-agent

## Acceptance criteria
- [ ] dangling work

## Blocked by
- 999
EOF
  cat > "$dir/docs/issues/006-multidep.md" <<'EOF'
# Multidep
Status: ready-for-agent
Goal: goals/6-multidep.md

## Acceptance criteria
- [ ] multi-dep work

## Blocked by
- 001
- 002
EOF
  cat > "$dir/docs/issues/007-fm.md" <<'EOF'
---
depends: [002]
risk: MECHANICAL
---
# Fm
Status: ready-for-agent

## Acceptance criteria
- [ ] fm work

## Blocked by
- 001
EOF
  touch "$dir/goals/1-base.md" "$dir/goals/2-active.md" "$dir/goals/3-ready.md" "$dir/goals/4-blocked.md" "$dir/goals/6-multidep.md"
  printf 'goals/2-active.md\n' > "$dir/.state/active-goal"
  cat > "$dir/scripts/next-task.sh" <<'EOF'
#!/usr/bin/env bash
echo next
EOF
  chmod +x "$dir/scripts/next-task.sh"
}

# Fixture for the triage-status fallback: issues with NO goal link, one per
# Status word. The build gate is "none" for all of them, so the node colour must
# fall back to the Status: line via effGate (done->green, blocked->blocked,
# ready-for-human->review, ready-for-agent->todo, needs-info->unknown). ALL_DONE
# is set to prove it no longer greens goalless issues.
make_status_fixture() {
  local dir="$1"
  mkdir -p "$dir/docs/issues" "$dir/goals" "$dir/.state"
  cat > "$dir/docs/issues/001-d.md" <<'EOF'
# D
Status: done (2026-01-01 — shipped)

## Acceptance criteria
- [x] done
EOF
  cat > "$dir/docs/issues/002-b.md" <<'EOF'
# B
Status: blocked / deferred-research

## Acceptance criteria
- [ ] blocked
EOF
  cat > "$dir/docs/issues/003-h.md" <<'EOF'
# H
Status: ready-for-human

## Acceptance criteria
- [ ] human
EOF
  cat > "$dir/docs/issues/004-a.md" <<'EOF'
# A
Status: ready-for-agent

## Acceptance criteria
- [ ] agent
EOF
  cat > "$dir/docs/issues/005-i.md" <<'EOF'
# I
Status: needs-info

## Acceptance criteria
- [ ] info
EOF
  printf 'ALL_DONE\n' > "$dir/.state/active-goal"
}

# Fixture for the service ("서비스 흐름") tab: a docs/spec/service-flow.md with
# two markdown tables. Exercises kind-from-group derivation, a groupless user
# node, em-dash placeholders, col/row, depends_on, and a nested parent group
# (cloud) that must enclose its child groups' members. ASCII labels keep the
# substring assertions locale-independent.
make_service_fixture() {
  local dir="$1"
  mkdir -p "$dir/docs/spec"
  cat > "$dir/docs/spec/service-flow.md" <<'EOF'
---
spec: architecture
---
# Architecture

## Groups
| id | label | kind | parent |
| --- | --- | --- | --- |
| cloud | Cloud | infra | — |
| backend | Backend | be | cloud |
| data | Data | db | cloud |
| frontend | Frontend | fe | — |
| external | External | api | — |

## Components
| id | name | group | col | row | depends_on | phase | desc |
| --- | --- | --- | --- | --- | --- | --- | --- |
| u | User | — | 0 | 0 | — | — | end user |
| upload | Upload | frontend | 3 | 0 | u | 8 | survey + photos |
| hook | Hook | backend | 4 | 1 | upload | 8 | webhook in |
| store | Store | data | 9 | 3 | hook | 8 | storage |
| mp | MP | external | 7 | 5 | hook | 1 | model |

## Use-cases
| uc | name | trigger | step | component | action | kind |
| --- | --- | --- | --- | --- | --- | --- |
| submit | Submit | user submits | 1 | upload | send | main |
| submit | Submit | — | 2 | hook | receive | main |
| submit | Submit | model down | 2 | mp | fallback | edge |
EOF
}

emit_fixture() {
  local dir="$1"
  local out="$dir/roadmap.html"
  ROADMAP_SOURCE_ROOT="$dir" bash "$GEN" "$out" >/dev/null || fail "generator failed"
  grep -F 'const DATA = ' "$out" || fail "missing DATA"
}

assert_has() {
  local data="$1"
  local needle="$2"
  printf '%s' "$data" | grep -F "$needle" >/dev/null || fail "missing pattern: $needle"
}

test_deps() {
  local tmp data
  tmp="$(portable_mktemp_dir)"
  make_fixture "$tmp"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"id":"002","title":"Active","issueStatus":"ready-for-agent","gate":"active","goal":"2-active","accDone":0,"accTotal":1,"deps":["001"],"ready":false,"danglingDeps":[]'
  assert_has "$data" '"id":"005","title":"Dangling","issueStatus":"ready-for-agent","gate":"none","goal":"","accDone":0,"accTotal":1,"deps":["999"],"ready":false,"danglingDeps":["999"]'
  # A node with 2+ "Blocked by" ids must stay a SINGLE record carrying both
  # deps — guards the row-split bug (finding 2026-06-06T0100).
  assert_has "$data" '"id":"006","title":"Multidep","issueStatus":"ready-for-agent","gate":"deferred","goal":"6-multidep","accDone":0,"accTotal":1,"deps":["001","002"],"ready":false,"danglingDeps":[]'
  # Frontmatter `depends:` is the machine contract and beats the prose
  # "Blocked by" fallback (007 declares [002] in frontmatter, 001 in prose).
  assert_has "$data" '"id":"007","title":"Fm","issueStatus":"ready-for-agent","gate":"none","goal":"","accDone":0,"accTotal":1,"deps":["002"],"ready":false,"danglingDeps":[]'
}

test_ready() {
  local tmp data
  tmp="$(portable_mktemp_dir)"
  make_fixture "$tmp"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"readyCount":1'
  assert_has "$data" '"id":"001","title":"Base","issueStatus":"ready-for-agent","gate":"green","goal":"1-base","accDone":1,"accTotal":1,"deps":[],"ready":false'
  assert_has "$data" '"id":"002","title":"Active","issueStatus":"ready-for-agent","gate":"active","goal":"2-active","accDone":0,"accTotal":1,"deps":["001"],"ready":false'
  assert_has "$data" '"id":"003","title":"Ready","issueStatus":"ready-for-agent","gate":"deferred","goal":"3-ready","accDone":0,"accTotal":1,"deps":["001"],"ready":true'
  assert_has "$data" '"id":"004","title":"Blocked","issueStatus":"ready-for-agent","gate":"deferred","goal":"4-blocked","accDone":0,"accTotal":1,"deps":["002"],"ready":false'
}

test_shading() {
  local tmp data
  tmp="$(portable_mktemp_dir)"
  make_fixture "$tmp"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"id":"001","title":"Base","issueStatus":"ready-for-agent","gate":"green"'
  assert_has "$data" '"id":"002","title":"Active","issueStatus":"ready-for-agent","gate":"active"'
  assert_has "$data" '"id":"003","title":"Ready","issueStatus":"ready-for-agent","gate":"deferred"'
  assert_has "$data" '"id":"005","title":"Dangling","issueStatus":"ready-for-agent","gate":"none"'

  rm -f "$tmp/.state/active-goal"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"id":"001","title":"Base","issueStatus":"ready-for-agent","gate":"unknown"'
  assert_has "$data" '"id":"002","title":"Active","issueStatus":"ready-for-agent","gate":"unknown"'
  assert_has "$data" '"id":"003","title":"Ready","issueStatus":"ready-for-agent","gate":"unknown"'

  printf 'ALL_DONE\n' > "$tmp/.state/active-goal"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"id":"001","title":"Base","issueStatus":"ready-for-agent","gate":"green"'
  assert_has "$data" '"id":"002","title":"Active","issueStatus":"ready-for-agent","gate":"green"'
  assert_has "$data" '"id":"003","title":"Ready","issueStatus":"ready-for-agent","gate":"green"'
}

# Triage-status fallback: an issue with NO goal keeps gate "none" but gets an
# effGate derived from its Status: line, so the node is coloured by triage state
# (done/blocked/ready-for-human/ready-for-agent/needs-info) rather than a flat
# grey. Only a ready-for-agent issue with deps satisfied is "지금 시작 가능".
test_status() {
  local tmp data
  tmp="$(portable_mktemp_dir)"
  make_status_fixture "$tmp"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"id":"001","title":"D","issueStatus":"done (2026-01-01 — shipped)","gate":"none","goal":"","accDone":1,"accTotal":1,"deps":[],"ready":false,"danglingDeps":[],"desc":"","accAuthority":"issue-checkbox","effGate":"green"'
  assert_has "$data" '"id":"002","title":"B","issueStatus":"blocked / deferred-research","gate":"none","goal":"","accDone":0,"accTotal":1,"deps":[],"ready":false,"danglingDeps":[],"desc":"","accAuthority":"issue-checkbox","effGate":"blocked"'
  assert_has "$data" '"id":"003","title":"H","issueStatus":"ready-for-human","gate":"none","goal":"","accDone":0,"accTotal":1,"deps":[],"ready":false,"danglingDeps":[],"desc":"","accAuthority":"issue-checkbox","effGate":"review"'
  assert_has "$data" '"id":"004","title":"A","issueStatus":"ready-for-agent","gate":"none","goal":"","accDone":0,"accTotal":1,"deps":[],"ready":true,"danglingDeps":[],"desc":"","accAuthority":"issue-checkbox","effGate":"todo"'
  assert_has "$data" '"id":"005","title":"I","issueStatus":"needs-info","gate":"none","goal":"","accDone":0,"accTotal":1,"deps":[],"ready":false,"danglingDeps":[],"desc":"","accAuthority":"issue-checkbox","effGate":"unknown"'
  assert_has "$data" '"readyCount":1'
}

# DATA.service contract: docs/spec/service-flow.md → {nodes,groups,usecases}.
test_service() {
  local tmp data
  tmp="$(portable_mktemp_dir)"
  make_service_fixture "$tmp"
  data="$(emit_fixture "$tmp")"

  # kind is derived from a node's group; groupless node → user. col/row and
  # depends_on are carried through verbatim (em-dash dep → empty []).
  assert_has "$data" '"id":"u","nm":"User","kind":"user","col":0,"row":0,"deps":[]'
  assert_has "$data" '"id":"upload","nm":"Upload","kind":"fe","col":3,"row":0,"deps":["u"]'
  assert_has "$data" '"id":"hook","nm":"Hook","kind":"be","col":4,"row":1,"deps":["upload"]'
  assert_has "$data" '"id":"store","nm":"Store","kind":"db","col":9,"row":3,"deps":["hook"]'
  assert_has "$data" '"id":"mp","nm":"MP","kind":"api","col":7,"row":5,"deps":["hook"]'

  # A parent group (referenced via `parent`) encloses every descendant group's
  # members and gets the larger pad/labelTop; leaf groups get the small pad.
  assert_has "$data" '"key":"cloud","kind":"infra","label":"Cloud","members":["hook","store"],"pad":30,"labelTop":22'
  assert_has "$data" '"key":"backend","kind":"be","label":"Backend","members":["hook"],"pad":12,"labelTop":18'
  assert_has "$data" '"key":"data","kind":"db","label":"Data","members":["store"],"pad":12,"labelTop":18'
  assert_has "$data" '"key":"frontend","kind":"fe","label":"Frontend","members":["upload"],"pad":12,"labelTop":18'

  # Use-cases (## Use-cases table): grouped by uc, ordered steps, kind=main|edge.
  # The use-case trigger = its first main row's trigger; an em-dash step trigger
  # normalises to an empty cond; an edge row carries its condition as cond.
  assert_has "$data" '"id":"submit","name":"Submit","trigger":"user submits","steps":['
  assert_has "$data" '{"step":1,"component":"upload","action":"send","kind":"main","cond":"user submits"}'
  assert_has "$data" '{"step":2,"component":"hook","action":"receive","kind":"main","cond":""}'
  assert_has "$data" '{"step":2,"component":"mp","action":"fallback","kind":"edge","cond":"model down"}'

  # Graceful: no service-flow.md → empty service (dashboard shows guidance).
  rm -f "$tmp/docs/spec/service-flow.md"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"service":{"nodes":[],"groups":[],"usecases":[]}'
}

# Generator-output validity (NOT render content). Guards the "generator emits
# a broken file → blank dashboard" class that the DATA-only groups cannot see:
# the HTML must embed DATA, close cleanly, and its <script> must be valid JS.
# Presentation-agnostic — any renderer passes. Verifying that the *promised UI
# elements actually draw* needs a headless DOM and stays an open gap (no
# finding file is tracked in the cleaned template).
test_render() {
  local tmp out
  tmp="$(portable_mktemp_dir)"
  make_fixture "$tmp"
  out="$tmp/roadmap.html"
  ROADMAP_SOURCE_ROOT="$tmp" bash "$GEN" "$out" >/dev/null || fail "generator failed"
  grep -F 'const DATA = ' "$out" >/dev/null || fail "render: DATA not embedded"
  grep -F '</html>' "$out" >/dev/null || fail "render: document not closed (truncated?)"
  if command -v node >/dev/null 2>&1; then
    awk '/^<script>$/{f=1;next} /^<\/script>$/{f=0} f' "$out" > "$tmp/embedded.js"
    node --check "$tmp/embedded.js" 2>/dev/null || fail "render: embedded JS failed node --check"
    echo "  embedded JS: node --check ok"
  else
    echo "  embedded JS: node absent — syntax check skipped"
  fi
}

case "$GROUP" in
  deps) test_deps ;;
  ready) test_ready ;;
  shading) test_shading ;;
  status) test_status ;;
  service) test_service ;;
  render) test_render ;;
  all) test_deps; test_ready; test_shading; test_status; test_service; test_render ;;
  *) fail "unknown group: $GROUP" ;;
esac

echo "roadmap-selftest: $GROUP passed"
