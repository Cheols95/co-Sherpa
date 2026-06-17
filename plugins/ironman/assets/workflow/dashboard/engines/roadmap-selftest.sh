#!/usr/bin/env bash
# Contract tests for roadmap DATA emitted by roadmap.sh.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$ROOT/dashboard/engines/roadmap.sh"
GROUP="${1:-all}"

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
  tmp="$(mktemp -d)"
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
  tmp="$(mktemp -d)"
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
  tmp="$(mktemp -d)"
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

# DATA.service contract: docs/spec/service-flow.md → {nodes,groups}.
test_service() {
  local tmp data
  tmp="$(mktemp -d)"
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

  # Graceful: no service-flow.md → empty service (dashboard shows guidance).
  rm -f "$tmp/docs/spec/service-flow.md"
  data="$(emit_fixture "$tmp")"
  assert_has "$data" '"service":{"nodes":[],"groups":[]}'
}

# Generator-output validity (NOT render content). Guards the "generator emits
# a broken file → blank dashboard" class that the DATA-only groups cannot see:
# the HTML must embed DATA, close cleanly, and its <script> must be valid JS.
# Presentation-agnostic — any renderer passes. Verifying that the *promised UI
# elements actually draw* needs a headless DOM and stays an open gap (no
# finding file is tracked in the cleaned template).
test_render() {
  local tmp out
  tmp="$(mktemp -d)"
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
  service) test_service ;;
  render) test_render ;;
  all) test_deps; test_ready; test_shading; test_service; test_render ;;
  *) fail "unknown group: $GROUP" ;;
esac

echo "roadmap-selftest: $GROUP passed"
