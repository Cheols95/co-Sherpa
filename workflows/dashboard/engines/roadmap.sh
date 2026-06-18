#!/usr/bin/env bash
# Generate a self-contained HTML roadmap dashboard.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE_ROOT="${ROADMAP_SOURCE_ROOT:-$ROOT}"
OUT="${1:-$ROOT/dashboard/roadmap.html}"
mkdir -p "$(dirname "$OUT")"
OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
cd "$SOURCE_ROOT"

# shared depends parser (single source of truth, also used by issues-graph-check.sh)
. "$ROOT/scripts/_deps-lib.sh"
. "$ROOT/scripts/_portable.sh"

json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/ /g' | tr -d '\r\n'
}

goal_num() {
  printf '%s' "$1" | sed -E 's/^_?([0-9]+).*/\1/'
}

gate_for() {
  local stem="$1"
  [ -z "$stem" ] && { echo none; return; }

  local active="$ACTIVE_GOAL"
  if [ "$active" = "ALL_DONE" ]; then
    echo green
    return
  fi
  if [ -z "$active" ]; then
    echo unknown
    return
  fi

  local active_num n
  active_num="$(goal_num "$(basename "$active" .md)")"
  n="$(goal_num "$stem")"
  if [ "$n" -lt "$active_num" ] 2>/dev/null; then
    echo green
  elif [ "$n" -eq "$active_num" ] 2>/dev/null; then
    echo active
  elif [ "$n" -gt "$active_num" ] 2>/dev/null; then
    echo deferred
  else
    echo unknown
  fi
}

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '')"
ACTIVE_GOAL=""
[ -f "$SOURCE_ROOT/.state/active-goal" ] && ACTIVE_GOAL="$(cat "$SOURCE_ROOT/.state/active-goal" 2>/dev/null)"

FEATURE_ROWS=""
IDS=""
ISSUE_COUNT=0

if [ -d "$SOURCE_ROOT/docs/issues" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
    base="$(basename "$f" .md)"
    id="$(issue_id_for "$f")"
    slug="${base#*-}"
    IDS="$IDS $id"

    title="$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# *//')"
    [ -z "$title" ] && title="$slug"
    issue_status="$(grep -m1 -iE '^[[:space:]]*Status:' "$f" 2>/dev/null | sed -E 's/^[[:space:]]*[Ss]tatus:[[:space:]]*//')"
    acc_total="$(grep -cE '^[[:space:]]*[-*] \[[ xX]\]' "$f" 2>/dev/null || true)"
    acc_done="$(grep -cE '^[[:space:]]*[-*] \[[xX]\]' "$f" 2>/dev/null || true)"

    # Short human description = first prose paragraph under "## What to build".
    desc="$(awk '
      /^##[[:space:]]+[Ww]hat to build/{cap=1; next}
      cap && /^##[[:space:]]/{exit}
      cap{
        if($0 ~ /^[[:space:]]*$/){ if(body!="") exit; else next }
        if($0 ~ /^end-to-end:/){ exit }
        if($0 ~ /^[[:space:]]*[-*][[:space:]]/){ exit }
        if($0 ~ /^>/){ next }
        gsub(/\|/," ")
        body=(body==""?$0:body" "$0)
      }
      END{ print body }
    ' "$f" 2>/dev/null)"

    # depends parser lives in scripts/_deps-lib.sh (single source of truth,
    # shared with issues-graph-check.sh). frontmatter `depends:` wins, prose
    # "## Blocked by" is the fallback; space-separated, safe for the record.
    deps="$(parse_issue_deps "$f" "$id")"
    deps_js=""
    for d in $deps; do
      [ -n "$deps_js" ] && deps_js="$deps_js,"
      deps_js="$deps_js\"$d\""
    done

    goal_stem="$(grep -m1 -iE '^[[:space:]]*(Goal|Implements):' "$f" 2>/dev/null |
      sed -E 's/^[^:]*:[[:space:]]*//' | sed -E 's#^goals/##; s/\.md$//')"
    if [ -z "$goal_stem" ]; then
      gmatch="$(find "$SOURCE_ROOT/goals" -maxdepth 1 -type f -name "[0-9]*-${slug}.md" 2>/dev/null | head -1)"
      [ -n "$gmatch" ] && goal_stem="$(basename "$gmatch" .md)"
    fi
    gate="$(gate_for "$goal_stem")"

    row="${id}|${deps}|${gate}|${goal_stem}|${title}|${issue_status}|${acc_done}|${acc_total}|${desc}"
    FEATURE_ROWS="${FEATURE_ROWS}${row}"$'\n'
  done <<EOF
$(find "$SOURCE_ROOT/docs/issues" -maxdepth 1 -type f -name '[0-9]*.md' 2>/dev/null | portable_version_sort)
EOF
fi

FEATURES_JSON=""
READY_COUNT=0

while IFS='|' read -r id deps gate goal_stem title issue_status acc_done acc_total desc; do
  [ -z "$id" ] && continue

  dangling_js=""
  for d in $deps; do
    case " $IDS " in
      *" $d "*) ;;
      *)
        [ -n "$dangling_js" ] && dangling_js="$dangling_js,"
        dangling_js="$dangling_js\"$d\""
        ;;
    esac
  done

  ready=true
  case "$gate" in
    green|active) ready=false ;;
  esac
  for d in $deps; do
    dep_gate="$(printf '%s' "$FEATURE_ROWS" | awk -F'|' -v id="$d" '$1 == id { print $3; exit }')"
    [ "$dep_gate" = "green" ] || ready=false
  done
  [ "$ready" = true ] && READY_COUNT=$((READY_COUNT + 1))

  deps_js=""
  for d in $deps; do
    [ -n "$deps_js" ] && deps_js="$deps_js,"
    deps_js="$deps_js\"$d\""
  done

  [ -n "$FEATURES_JSON" ] && FEATURES_JSON="$FEATURES_JSON,"
  FEATURES_JSON="$FEATURES_JSON{\"id\":\"$(printf '%s' "$id" | json_escape)\",\"title\":\"$(printf '%s' "$title" | json_escape)\",\"issueStatus\":\"$(printf '%s' "$issue_status" | json_escape)\",\"gate\":\"$gate\",\"goal\":\"$(printf '%s' "$goal_stem" | json_escape)\",\"accDone\":${acc_done:-0},\"accTotal\":${acc_total:-0},\"deps\":[$deps_js],\"ready\":$ready,\"danglingDeps\":[$dangling_js],\"desc\":\"$(printf '%s' "$desc" | json_escape)\"}"
done <<EOF
$FEATURE_ROWS
EOF

DEMO=false
if [ "$ISSUE_COUNT" -eq 0 ]; then
  DEMO=true
  READY_COUNT=1
  FEATURES_JSON='{"id":"001","title":"Example feature","issueStatus":"ready-for-agent","gate":"unknown","goal":"","accDone":0,"accTotal":1,"deps":[],"ready":true,"danglingDeps":[],"desc":"예시 모듈입니다. docs/issues/ 에 이슈를 추가하면 여기에 실제 모듈이 흐름도로 나타납니다."}'
fi

# ---- Service flow (docs/spec/service-flow.md) -> DATA.service ----
# Optional contract doc for the "서비스 흐름" tab. Two markdown tables:
#   ## Groups      | id | label | kind | parent |          (deploy boxes; parent = nesting)
#   ## Components  | id | name | group | col | row | depends_on | phase | desc |
# kind is DERIVED from a component's group (groupless -> user); a group's
# members = its own components + every descendant group's components, so a
# parent box (e.g. cloud) encloses its child boxes. Missing file or empty
# tables ⇒ empty service ⇒ dashboard renders a graceful guidance state.
SVC_FILE="$SOURCE_ROOT/docs/spec/service-flow.md"

arch_table() {
  # $1 = section name (Groups|Components). Emits one TAB-separated row per
  # data row; header + separator rows skipped, cells trimmed. Same awk-on-'|'
  # grain as the issue parser above.
  awk -v sec="$1" '
    $0 ~ "^##[[:space:]]+" sec "([[:space:]]|$)" { insec=1; next }
    insec && /^##[[:space:]]/ { insec=0 }
    insec && /^[[:space:]]*\|/ {
      n = split($0, a, "|")
      row=""; first=""
      for (i = 2; i < n; i++) {
        cell = a[i]
        gsub(/^[[:space:]]+/, "", cell); gsub(/[[:space:]]+$/, "", cell)
        if (i == 2) { first = cell; row = cell } else { row = row "\t" cell }
      }
      if (first == "id" || first == "") next        # header row
      if (first ~ /^:?-+:?$/) next                   # --- separator row
      print row
    }
  ' "$SVC_FILE" 2>/dev/null
}

norm_dash() {
  # Map em/en-dash or bare hyphen placeholders to empty (means "none").
  case "$1" in
    '—'|'–'|'-'|'') printf '' ;;
    *) printf '%s' "$1" ;;
  esac
}

GROUP_ROWS=""
COMP_ROWS=""
SERVICE_NODES_JSON=""
SERVICE_GROUPS_JSON=""

if [ -f "$SVC_FILE" ]; then
  # Groups -> rows: gid|gkind|gparent|glabel
  while IFS=$'\t' read -r gid glabel gkind gparent; do
    [ -z "$gid" ] && continue
    gparent="$(norm_dash "$gparent")"
    GROUP_ROWS="${GROUP_ROWS}${gid}|${gkind}|${gparent}|${glabel}"$'\n'
  done <<EOF
$(arch_table Groups)
EOF

  # Components -> rows: cid|kind|cgroup|ccol|crow|cphase|deps|cname|cdesc
  while IFS=$'\t' read -r cid cname cgroup ccol crow cdeps cphase cdesc; do
    [ -z "$cid" ] && continue
    cgroup="$(norm_dash "$cgroup")"
    if [ -z "$cgroup" ]; then
      kind="user"
    else
      kind="$(printf '%s' "$GROUP_ROWS" | awk -F'|' -v g="$cgroup" '$1==g{print $2; exit}')"
      [ -z "$kind" ] && kind="user"
    fi
    case "$ccol" in ''|*[!0-9]*) ccol=0 ;; esac
    case "$crow" in ''|*[!0-9]*) crow=0 ;; esac
    cdeps="$(printf '%s' "$cdeps" | tr ',' ' ')"
    deps_clean=""
    for d in $cdeps; do
      d="$(norm_dash "$d")"
      [ -z "$d" ] && continue
      deps_clean="$deps_clean $d"
    done
    COMP_ROWS="${COMP_ROWS}${cid}|${kind}|${cgroup}|${ccol}|${crow}|${cphase}|${deps_clean# }|${cname}|${cdesc}"$'\n'
  done <<EOF
$(arch_table Components)
EOF

  # nodes JSON
  while IFS='|' read -r cid kind cgroup ccol crow cphase deps cname cdesc; do
    [ -z "$cid" ] && continue
    deps_js=""
    for d in $deps; do
      [ -n "$deps_js" ] && deps_js="$deps_js,"
      deps_js="$deps_js\"$(printf '%s' "$d" | json_escape)\""
    done
    [ -n "$SERVICE_NODES_JSON" ] && SERVICE_NODES_JSON="$SERVICE_NODES_JSON,"
    SERVICE_NODES_JSON="$SERVICE_NODES_JSON{\"id\":\"$(printf '%s' "$cid" | json_escape)\",\"nm\":\"$(printf '%s' "$cname" | json_escape)\",\"kind\":\"$(printf '%s' "$kind" | json_escape)\",\"col\":${ccol},\"row\":${crow},\"deps\":[$deps_js],\"phase\":\"$(printf '%s' "$cphase" | json_escape)\",\"desc\":\"$(printf '%s' "$cdesc" | json_escape)\"}"
  done <<EOF
$COMP_ROWS
EOF

  # groups JSON (transitive members + pad/labelTop from parent-ness)
  while IFS='|' read -r gid gkind gparent glabel; do
    [ -z "$gid" ] && continue
    members_js=""
    while IFS='|' read -r cid2 kind2 cgroup2 rest2; do
      [ -z "$cid2" ] && continue
      [ -z "$cgroup2" ] && continue
      g="$cgroup2"; hit=0; seen=" "
      while [ -n "$g" ]; do
        case "$seen" in *" $g "*) break ;; esac
        seen="$seen$g "
        if [ "$g" = "$gid" ]; then hit=1; break; fi
        g="$(printf '%s' "$GROUP_ROWS" | awk -F'|' -v x="$g" '$1==x{print $3; exit}')"
      done
      if [ "$hit" = 1 ]; then
        [ -n "$members_js" ] && members_js="$members_js,"
        members_js="$members_js\"$(printf '%s' "$cid2" | json_escape)\""
      fi
    done <<EOF2
$COMP_ROWS
EOF2
    if printf '%s' "$GROUP_ROWS" | awk -F'|' -v id="$gid" '$3==id{f=1} END{exit !f}'; then
      pad=30; labelTop=22
    else
      pad=12; labelTop=18
    fi
    [ -n "$SERVICE_GROUPS_JSON" ] && SERVICE_GROUPS_JSON="$SERVICE_GROUPS_JSON,"
    SERVICE_GROUPS_JSON="$SERVICE_GROUPS_JSON{\"key\":\"$(printf '%s' "$gid" | json_escape)\",\"kind\":\"$(printf '%s' "$gkind" | json_escape)\",\"label\":\"$(printf '%s' "$glabel" | json_escape)\",\"members\":[$members_js],\"pad\":${pad},\"labelTop\":${labelTop}}"
  done <<EOF
$GROUP_ROWS
EOF
fi

SERVICE_JSON="{\"nodes\":[${SERVICE_NODES_JSON}],\"groups\":[${SERVICE_GROUPS_JSON}]}"

NEXT_TASK=""
if [ -f "$SOURCE_ROOT/scripts/next-task.sh" ]; then
  NEXT_TASK="$(portable_timeout 5 bash "$SOURCE_ROOT/scripts/next-task.sh" 2>/dev/null | head -3 | json_escape || true)"
fi
[ -z "$NEXT_TASK" ] && NEXT_TASK="No next-task output."

DATA_JSON="{\"generatedAt\":\"$NOW\",\"demo\":$DEMO,\"activeGoal\":\"$(printf '%s' "$ACTIVE_GOAL" | json_escape)\",\"nextTask\":\"$NEXT_TASK\",\"readyCount\":$READY_COUNT,\"features\":[${FEATURES_JSON}],\"codeEdges\":[],\"service\":${SERVICE_JSON}}"

mkdir -p "$(dirname "$OUT")"
cat > "$OUT" <<'HTML_HEAD'
<!doctype html>
<html lang="ko" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Roadmap Dashboard</title>
<style>
  :root{
    --bg:#0e1217;--panel:#161e26;--panel2:#1b242e;--surface:#10171e;--inset:#0c1116;--line:#2b3742;--text:#e8eef4;--muted:#93a1ad;
    /* roadmap gate colors */
    --green:#22c55e;--green-bg:#10311f;--active:#f59e0b;--active-bg:#36280a;
    --deferred:#3b82f6;--deferred-bg:#15233f;--deferred-bd:#33527e;--unknown:#7c8a97;--unknown-bg:#1b232b;
    --ready:#14b8a6;--warn:#fb7185;
    /* service kind colors */
    --user:#94a3b8;--fe:#14b8a6;--be:#f59e0b;--api:#a855f7;--db:#3b82f6;--infra:#64748b;
    --user-bg:#1b232b;--fe-bg:#0c2b28;--be-bg:#2a2109;--api-bg:#241036;--db-bg:#15233f;
    --edge:#4a5a67;--edge-hot:#14b8a6
  }
  html[data-theme="light"]{
    --bg:#eceff3;--panel:#ffffff;--panel2:#e6eaef;--surface:#ffffff;--inset:#f1f4f7;--line:#d3dae1;--text:#1b2530;--muted:#5d6b78;
    --green-bg:#e6f6ec;--active-bg:#fcefd6;--deferred-bg:#e8eefb;--deferred-bd:#aac3e8;--unknown-bg:#eef1f5;
    --user-bg:#eef1f5;--fe-bg:#dcf5ef;--be-bg:#fcefd6;--api-bg:#f3e8fc;--db-bg:#e8eefb;
    --edge:#9aa7b3
  }
  *{box-sizing:border-box}
  body{margin:0;font-family:Segoe UI,Malgun Gothic,Apple SD Gothic Neo,Arial,sans-serif;background:var(--bg);color:var(--text)}
  header{padding:12px 22px;border-bottom:1px solid var(--line);background:var(--surface)}
  .hrow{display:flex;justify-content:space-between;align-items:center;gap:12px}
  h1{font-size:18px;margin:0}
  .hbtns{display:flex;gap:8px}
  .toggle{background:var(--panel2);color:var(--text);border:1px solid var(--line);border-radius:8px;padding:6px 12px;font-size:12px;cursor:pointer}
  .toggle:hover{border-color:var(--muted)}
  .htitle{display:flex;align-items:center;gap:16px;flex-wrap:wrap}
  .tabs{display:flex;gap:7px;margin:0}
  .tab{background:transparent;color:var(--muted);border:1px solid var(--line);border-radius:8px;padding:7px 14px;font-size:13px;font-weight:600;cursor:pointer}
  .tab:hover{color:var(--text)}
  .tab.active{background:var(--panel2);color:var(--text);border-color:var(--muted)}
  .sub{color:var(--muted);font-size:12.5px;margin:0;text-align:right;flex:1 1 auto}
  .legendrow{display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap;margin-top:10px}
  .nextguide{font-size:13px;line-height:1.6;color:var(--text)}
  .legend{display:flex;gap:13px;flex-wrap:wrap;font-size:12px;color:var(--muted);align-items:center}
  .legend span{display:inline-flex;align-items:center;gap:5px}
  .legend .dot{width:11px;height:11px;border-radius:3px;border:1px solid #0006}
  .dot.green{background:var(--green)} .dot.active{background:var(--active)} .dot.deferred{background:var(--deferred)} .dot.unknown{background:var(--unknown)}
  .dot.user{background:var(--user)} .dot.fe{background:var(--fe)} .dot.be{background:var(--be)} .dot.api{background:var(--api)} .dot.db{background:var(--db)} .dot.infra{background:var(--infra)}
  main{display:grid;grid-template-columns:minmax(0,1fr) 340px;height:calc(100vh - 150px)}
  #wrap.collapsed main{grid-template-columns:1fr}
  #wrap.collapsed aside{display:none}
  .board{position:relative;overflow:hidden;padding:0;cursor:grab;user-select:none}
  .board.grabbing{cursor:grabbing}
  .empty{padding:40px 30px;color:var(--muted);font-size:14px;line-height:1.8}
  .flow{position:relative;transform-origin:0 0;will-change:transform}
  .zoomctl{position:absolute;left:12px;bottom:12px;z-index:5;display:flex;gap:6px;align-items:center;background:var(--surface);border:1px solid var(--line);border-radius:10px;padding:5px;box-shadow:0 4px 14px #0005}
  .zoomctl button{width:30px;height:30px;border:1px solid var(--line);background:var(--panel2);color:var(--text);border-radius:7px;font-size:16px;cursor:pointer;line-height:1;padding:0}
  .zoomctl button:hover{border-color:var(--muted)}
  .zoomctl .lvl{min-width:46px;text-align:center;font-size:11px;color:var(--muted)}
  .grp{position:absolute;z-index:0;border:1.5px solid var(--line);border-radius:12px;pointer-events:none;background:#ffffff05}
  .grp.infra{border-color:#64748b77;background:#64748b10;border-style:dashed} .grp.be{border-color:#f59e0b66;background:#f59e0b09}
  .grp.fe{border-color:#14b8a666;background:#14b8a609} .grp.api{border-color:#a855f766;background:#a855f70b} .grp.db{border-color:#3b82f666;background:#3b82f60d}
  .grp-label{position:absolute;left:0;top:0;font-size:11px;font-weight:700;color:var(--text);background:var(--inset);border:1px solid var(--line);border-top:0;border-left:0;padding:3px 10px;border-radius:11px 0 9px 0}
  .edges{position:absolute;left:0;top:0;z-index:1;pointer-events:none;overflow:visible}
  .edges path{fill:none;stroke:var(--edge);stroke-width:2}
  .edges path.side{stroke:#8493a0;stroke-dasharray:5 4;stroke-width:1.7}
  .edges path.hot{stroke:var(--edge-hot);stroke-width:3;stroke-dasharray:none}
  .node{position:absolute;z-index:2;border:1.5px solid var(--line);background:var(--panel);border-radius:10px;
        padding:9px 11px;cursor:pointer;overflow:hidden;transition:transform .08s ease,box-shadow .12s ease}
  .node:hover{transform:translateY(-2px);box-shadow:0 7px 20px #0008}
  .node.sel{outline:2px solid var(--text);outline-offset:1px}
  /* roadmap node internals */
  .node .nid{display:flex;justify-content:space-between;align-items:center;gap:6px;font-size:12px;font-weight:700;color:var(--muted)}
  .node .ntitle{font-size:13px;font-weight:700;line-height:1.3;margin:5px 0 7px;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
  .node .nfoot{display:flex;gap:6px;align-items:center;font-size:11px;color:var(--muted);white-space:nowrap}
  /* service node internals */
  .node .ph{font-size:10.5px;font-weight:700;color:var(--muted)}
  .node .nm{font-size:13.5px;font-weight:700;line-height:1.22;margin:3px 0 6px;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
  .node .foot{display:flex;justify-content:space-between;align-items:center;font-size:11px;color:var(--muted);gap:6px}
  /* roadmap gate fills */
  .node.green{background:var(--green-bg);border-color:var(--green)}
  .node.active{background:var(--active-bg);border-color:var(--active)}
  .node.deferred{background:var(--deferred-bg);border-color:var(--deferred-bd)}
  .node.unknown,.node.none{background:var(--unknown-bg);border-color:var(--unknown)}
  /* service kind fills */
  .node.user{background:var(--user-bg);border-color:var(--user)} .node.fe{background:var(--fe-bg);border-color:var(--fe)} .node.be{background:var(--be-bg);border-color:var(--be)}
  .node.api{background:var(--api-bg);border-color:var(--api)} .node.db{background:var(--db-bg);border-color:var(--db)}
  .node.ready{box-shadow:0 0 0 1px var(--ready),0 0 16px #14b8a644}
  .node.ready:hover{box-shadow:0 0 0 1px var(--ready),0 7px 20px #0008}
  @keyframes apulse{0%,100%{box-shadow:0 0 0 1px var(--active),0 0 8px #f59e0b22}50%{box-shadow:0 0 0 1px var(--active),0 0 20px #f59e0b55}}
  .node.active{animation:apulse 2.4s ease-in-out infinite}
  .flag{font-size:10px;color:#04231f;background:var(--ready);padding:2px 7px;border-radius:999px;font-weight:800;white-space:nowrap}
  .dang{color:var(--warn);border:1px solid var(--warn);border-radius:999px;padding:1px 6px}
  aside{border-left:1px solid var(--line);background:var(--surface);padding:16px;overflow:auto}
  aside h3{font-size:12px;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;margin:16px 0 6px}
  aside h3:first-child{margin-top:0}
  .cta{background:var(--panel2);border:1px solid var(--line);border-radius:10px;padding:13px}
  .cta-big{font-size:15px;font-weight:700}
  .cta-big b{color:var(--ready);font-size:19px;margin:0 2px}
  .cta-sub{font-size:12px;color:var(--muted);margin-top:5px}
  .cta-note{font-size:11.5px;color:var(--muted);margin-top:10px;line-height:1.55}
  .cta-warn{font-size:11.5px;color:var(--warn);margin-top:8px;line-height:1.55}
  code{background:var(--inset);border:1px solid var(--line);border-radius:4px;padding:1px 5px;font-size:11px}
  pre{white-space:pre-wrap;word-break:break-word;font-size:12px;color:var(--text);background:var(--inset);border:1px solid var(--line);border-radius:8px;padding:10px;margin:0}
  .detail{font-size:13px;line-height:1.5}
  .d-id,.d-ph{font-size:12px;color:var(--muted);font-weight:700;display:flex;align-items:center;gap:7px;flex-wrap:wrap}
  .d-status{border:1px solid currentColor;border-radius:999px;padding:1px 8px;font-size:11px}
  .d-status.green{color:var(--green)} .d-status.active{color:var(--active)} .d-status.deferred{color:var(--deferred)} .d-status.unknown,.d-status.none{color:var(--unknown)}
  .d-status.user{color:var(--user)} .d-status.fe{color:var(--fe)} .d-status.be{color:var(--be)} .d-status.api{color:var(--api)} .d-status.db{color:var(--db)}
  .d-title{font-size:15px;font-weight:700;margin:6px 0 9px;line-height:1.3}
  .d-desc{color:var(--text);background:var(--inset);border:1px solid var(--line);border-radius:8px;padding:10px;margin-bottom:11px}
  .d-rel{display:flex;justify-content:space-between;gap:10px;padding:6px 0;border-top:1px solid var(--line);font-size:12px}
  .d-rel b{color:var(--muted);font-weight:600} .d-rel span{text-align:right}
  .d-link{color:var(--fe);font-weight:700}
  .d-warn{margin-top:10px;color:var(--warn);font-size:12px}
  .foot-note{padding:9px 22px;border-top:1px solid var(--line);background:var(--surface);color:var(--muted);font-size:11.5px}
  @media (max-width:860px){main{grid-template-columns:1fr;height:auto} aside{border-left:0;border-top:1px solid var(--line)}}
</style>
</head>
<body>
<div id="wrap">
<header>
  <div class="hrow">
    <div class="htitle">
      <h1>Roadmap Dashboard</h1>
      <div class="tabs">
        <button class="tab active" data-view="roadmap">🗺 개발 로드맵</button>
        <button class="tab" data-view="service">⚙ 서비스 흐름</button>
      </div>
    </div>
    <div class="hbtns">
      <button id="theme" class="toggle">☀ 라이트로</button>
      <button id="toggle" class="toggle">상세 패널 닫기 ✕</button>
    </div>
  </div>
  <div class="legendrow">
    <div class="legend" id="legend"></div>
    <div class="sub" id="summary"></div>
  </div>
</header>
<main>
  <section class="board" id="board"></section>
  <aside>
    <div id="roadmapExtras">
      <h3>다음 할 일</h3>
      <div class="cta"><div class="nextguide" id="nextGuide"></div></div>
    </div>
    <h3 id="panelHead">선택한 모듈</h3>
    <div id="detail" class="detail"></div>
  </aside>
</main>
</div>
<div class="foot-note" id="footNote"></div>
<script>
HTML_HEAD
printf 'const DATA = %s;\n' "$DATA_JSON" >> "$OUT"
cat >> "$OUT" <<'HTML_TAIL'
const board = document.getElementById('board');
const detail = document.getElementById('detail');
const F = DATA.features || [];
const SVC = DATA.service || { nodes: [], groups: [] };
const byId = {};
F.forEach(f => { byId[f.id] = f; });

function escapeHtml(s){
  return String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}
function cleanMd(s){
  return String(s).replace(/\*\*/g, '').replace(/`/g, '');
}
function buildIndex(ns){ const m = {}; ns.forEach(n => { m[n.id] = n; }); return m; }

const GATE_KO = { green: '완료', active: '진행 중', deferred: '대기', unknown: '미확인', none: '미확인' };
const KIND_LABEL = { user: '사용자', fe: '프론트엔드', be: '백엔드 · n8n', api: '외부 API', db: '데이터 · 저장', infra: '인프라' };

/* ===================== VIEW CONFIG ===================== */
const VIEWS = {
  roadmap: {
    mode: 'dag', nodes: F, idx: byId, panelHead: '선택한 모듈',
    NW: 220, NH: 104, CGAP: 78, RGAP: 22,
    summary(){
      return `${F.length}개 모듈 · 지금 시작 가능 ${DATA.readyCount}개 · 활성 목표: ${DATA.activeGoal || '미상'}` +
             (DATA.generatedAt ? ` · 생성 ${DATA.generatedAt}` : '');
    },
    legend:
      '<span><i class="dot green"></i>완료</span>' +
      '<span><i class="dot active"></i>진행 중</span>' +
      '<span><i class="dot deferred"></i>대기(미착수)</span>' +
      '<span><i class="dot unknown"></i>미확인</span>' +
      '<span><b style="color:var(--ready)">▶</b>지금 시작 가능</span>' +
      '<span><b style="color:var(--muted)">→</b>먼저 끝나야 할 순서</span>',
    cls: f => (f.gate || 'unknown') + (f.ready ? ' ready' : ''),
    color: f => 'var(' + ({ green: '--green', active: '--active', deferred: '--deferred', unknown: '--unknown', none: '--unknown' }[f.gate] || '--unknown') + ')',
    face(f){
      const dang = f.danglingDeps && f.danglingDeps.length;
      return `<div class="nid"><span>${escapeHtml(f.id)}</span>${f.ready ? '<span class="flag">▶ 지금 가능</span>' : ''}</div>` +
             `<div class="ntitle">${escapeHtml(f.title)}</div>` +
             `<div class="nfoot"><span>${GATE_KO[f.gate] || f.gate}</span>` +
             `${dang ? `<span class="dang">끊긴 의존 ${escapeHtml(f.danglingDeps.join(','))}</span>` : ''}</div>`;
    },
    panel(f){
      const unlocks = F.filter(x => (x.deps || []).indexOf(f.id) >= 0).map(x => x.id);
      const dep = (f.deps && f.deps.length) ? escapeHtml(f.deps.join(', ')) : '없음 — 바로 시작 가능';
      const unl = unlocks.length ? escapeHtml(unlocks.join(', ')) : '없음 (흐름의 끝)';
      const danged = (f.danglingDeps && f.danglingDeps.length)
        ? `<div class="d-warn">⚠ 끊긴 의존: ${escapeHtml(f.danglingDeps.join(', '))} — 존재하지 않는 모듈을 가리켜요</div>` : '';
      const cta = f.ready
        ? `<div class="cta" style="margin-top:14px">` +
          `<div class="cta-big">▶ 지금 시작 가능 <b>${DATA.readyCount}</b>개</div>` +
          `<div class="cta-sub">착수 가능 모듈: ${escapeHtml(F.filter(x => x.ready).map(x => x.id).join(', '))}</div>` +
          `<div class="cta-note">동시에 진행하려면 모듈마다 <code>git worktree</code>로 작업 폴더를 나누세요. 안전 수칙: <code>dashboard/README.md</code></div>` +
          `<div class="cta-warn">⚠ 계획상 독립이 곧 파일상 독립은 아니에요 — 같은 파일을 건드리면 충돌할 수 있어요.</div>` +
          `</div>`
        : '';
      return `<div class="d-id"><span>${escapeHtml(f.id)}</span><span class="d-status ${f.gate}">${GATE_KO[f.gate] || f.gate}</span>${f.ready ? '<span class="flag">▶ 지금 가능</span>' : ''}</div>` +
             `<div class="d-title">${escapeHtml(f.title)}</div>` +
             `<div class="d-desc">${f.desc ? escapeHtml(cleanMd(f.desc)) : '(설명 없음)'}</div>` +
             `<div class="d-rel"><b>먼저 끝나야 할 모듈</b><span>${dep}</span></div>` +
             `<div class="d-rel"><b>이걸 끝내면 풀리는 모듈</b><span>${unl}</span></div>` +
             `<div class="d-rel"><b>받아들임 기준</b><span>${f.accTotal}개</span></div>` +
             danged + cta;
    }
  },
  service: {
    mode: 'boxes', nodes: SVC.nodes || [], idx: buildIndex(SVC.nodes || []), groups: SVC.groups || [], panelHead: '선택한 구성요소',
    NW: 176, NH: 86, CGAP: 58, RGAP: 26,
    sideEdge: n => n.kind === 'api' || n.kind === 'db',
    summary(){
      return '운영 아키텍처 · 클라우드 경계 안에서 백엔드 파이프라인이 돌고, 프론트엔드·외부 API·DB가 안팎으로 연결 · 화살표 = 데이터 흐름';
    },
    legend:
      '<span><i class="dot fe"></i>프론트엔드</span><span><i class="dot be"></i>백엔드</span>' +
      '<span><i class="dot api"></i>외부 API</span><span><i class="dot db"></i>DB·저장</span>' +
      '<span><b style="color:var(--muted)">▭</b>큰 사각형 = 배포 경계</span>' +
      '<span><b style="color:var(--muted)">→</b>데이터 흐름</span><span><b style="color:var(--muted)">┄</b>API 호출·저장</span>',
    cls: n => n.kind,
    color: n => 'var(--' + (n.kind || 'user') + ')',
    face(n){
      return `<div class="ph">${KIND_LABEL[n.kind] || n.kind}</div><div class="nm">${escapeHtml(n.nm)}</div>` +
             `<div class="foot"><span>개발: Phase ${escapeHtml(n.phase)}</span></div>`;
    },
    panel(n){
      const outs = (SVC.nodes || []).filter(x => (x.deps || []).indexOf(n.id) >= 0).map(x => x.nm);
      const ins = (n.deps && n.deps.length) ? n.deps.map(d => (this.idx[d] || {}).nm || d).join(', ') : '— (시작점 / 외부)';
      const out = outs.length ? outs.join(', ') : '— (끝점 / 사용자에게 전달)';
      return `<div class="d-ph"><span>구성요소</span><span class="d-status ${n.kind}">${KIND_LABEL[n.kind] || n.kind}</span></div>` +
             `<div class="d-title">${escapeHtml(n.nm)}</div><div class="d-desc">${escapeHtml(n.desc)}</div>` +
             `<div class="d-rel"><b>받는 데이터(입력)</b><span>${escapeHtml(ins)}</span></div>` +
             `<div class="d-rel"><b>보내는 곳(출력)</b><span>${escapeHtml(out)}</span></div>` +
             `<div class="d-rel"><b>개발 단계</b><span class="d-link">Phase ${escapeHtml(n.phase)}</span></div>`;
    }
  }
};

/* ===================== SHARED RENDERER ===================== */
const NS = 'http://www.w3.org/2000/svg';
let NW, NH, CGAP, RGAP;
let selEl = null, edgeEls = [];

function depthOf(n, idx, stack){
  if (n._d !== undefined) return n._d;
  stack = stack || new Set();
  if (stack.has(n.id)) return (n._d = 0);
  stack.add(n.id);
  const ps = (n.deps || []).map(d => idx[d]).filter(Boolean);
  n._d = ps.length ? 1 + Math.max.apply(null, ps.map(x => depthOf(x, idx, stack))) : 0;
  stack.delete(n.id);
  return n._d;
}
function setHot(id, on){
  edgeEls.forEach(e => {
    if (e.dataset.from === id || e.dataset.to === id){
      e.classList.toggle('hot', on);
      e.style.stroke = on ? 'var(--edge-hot)' : (e.dataset.base || 'var(--edge)');
    }
  });
}
function makeFlow(W, H){
  const flow = document.createElement('div');
  flow.className = 'flow'; flow.style.width = W + 'px'; flow.style.height = H + 'px';
  const svg = document.createElementNS(NS, 'svg');
  svg.setAttribute('class', 'edges'); svg.setAttribute('width', W); svg.setAttribute('height', H);
  flow.appendChild(svg); flow._svg = svg;
  return flow;
}
function addEdge(svg, a, b, side, color){
  // Anchor on whichever of the 4 box sides faces the other box's center,
  // so an edge can leave a bottom-center and enter a top-center, etc.
  const acx = a._x + NW/2, acy = a._y + NH/2, bcx = b._x + NW/2, bcy = b._y + NH/2;
  const dx = bcx - acx, dy = bcy - acy;
  let x1, y1, x2, y2, c1x, c1y, c2x, c2y;
  if (Math.abs(dx) >= Math.abs(dy)){
    // horizontal-dominant → exit left/right side, enter opposite side
    if (dx >= 0){ x1 = a._x + NW; y1 = acy; x2 = b._x;      y2 = bcy; }
    else        { x1 = a._x;      y1 = acy; x2 = b._x + NW; y2 = bcy; }
    const off = Math.max(26, Math.abs(x2 - x1) * 0.5), s = dx >= 0 ? 1 : -1;
    c1x = x1 + off * s; c1y = y1; c2x = x2 - off * s; c2y = y2;
  } else {
    // vertical-dominant → exit top/bottom side, enter opposite side
    if (dy >= 0){ x1 = acx; y1 = a._y + NH; x2 = bcx; y2 = b._y; }
    else        { x1 = acx; y1 = a._y;      x2 = bcx; y2 = b._y + NH; }
    const off = Math.max(18, Math.abs(y2 - y1) * 0.5), s = dy >= 0 ? 1 : -1;
    c1x = x1; c1y = y1 + off * s; c2x = x2; c2y = y2 - off * s;
  }
  const col = color || 'var(--edge)';
  const path = document.createElementNS(NS, 'path');
  path.setAttribute('d', `M${x1},${y1} C${c1x},${c1y} ${c2x},${c2y} ${x2},${y2}`);
  if (side) path.setAttribute('class', 'side');
  path.style.stroke = col;
  path.dataset.base = col;
  path.dataset.from = a.id; path.dataset.to = b.id;
  svg.appendChild(path); edgeEls.push(path);

  // Self-drawn open-V arrowhead: colour + stroke-width match the edge, and
  // its angle = the curve's actual incoming tangent (c2 → end point). A
  // shared SVG marker with context-stroke proved unreliable across browsers.
  const ang = Math.atan2(y2 - c2y, x2 - c2x), L = 8, sp = Math.PI / 7;
  const h1x = x2 - L * Math.cos(ang - sp), h1y = y2 - L * Math.sin(ang - sp);
  const h2x = x2 - L * Math.cos(ang + sp), h2y = y2 - L * Math.sin(ang + sp);
  const head = document.createElementNS(NS, 'path');
  head.setAttribute('d', `M${h1x.toFixed(1)},${h1y.toFixed(1)} L${x2.toFixed(1)},${y2.toFixed(1)} L${h2x.toFixed(1)},${h2y.toFixed(1)}`);
  head.setAttribute('fill', 'none');
  head.setAttribute('stroke-linecap', 'round');
  head.setAttribute('stroke-linejoin', 'round');
  if (side) head.style.strokeDasharray = 'none';
  head.style.stroke = col;
  head.dataset.base = col;
  head.dataset.from = a.id; head.dataset.to = b.id;
  svg.appendChild(head); edgeEls.push(head);
}
function addNode(flow, cfg, n){
  const el = document.createElement('div');
  el.className = 'node ' + cfg.cls(n);
  el.style.left = n._x + 'px'; el.style.top = n._y + 'px'; el.style.width = NW + 'px'; el.style.height = NH + 'px';
  el.title = n.title ? (n.id + '  ' + n.title) : (n.nm || n.id);
  el.innerHTML = cfg.face(n);
  el.addEventListener('click', () => selectNode(cfg, n, el));
  el.addEventListener('mouseenter', () => setHot(n.id, true));
  el.addEventListener('mouseleave', () => setHot(n.id, false));
  flow.appendChild(el);
}
function selectNode(cfg, n, el){
  if (selEl) selEl.classList.remove('sel');
  selEl = el; el.classList.add('sel');
  detail.innerHTML = cfg.panel(n);
}
function posDag(cfg){
  const idx = cfg.idx;
  cfg.nodes.forEach(n => { n._d = undefined; });
  cfg.nodes.forEach(n => depthOf(n, idx));
  const cols = {};
  cfg.nodes.forEach(n => { (cols[n._d] = cols[n._d] || []).push(n); });
  const keys = Object.keys(cols).map(Number).sort((a, b) => a - b);
  let maxRows = 1; keys.forEach(k => { if (cols[k].length > maxRows) maxRows = cols[k].length; });
  const contentH = maxRows * NH + (maxRows - 1) * RGAP;
  keys.forEach((k, ci) => {
    const arr = cols[k], colH = arr.length * NH + (arr.length - 1) * RGAP, off = (contentH - colH) / 2;
    arr.forEach((n, ri) => { n._x = 24 + ci * (NW + CGAP); n._y = 24 + off + ri * (NH + RGAP); });
  });
  return { W: 48 + keys.length * NW + Math.max(0, keys.length - 1) * CGAP, H: 48 + contentH, groups: null };
}
function posBoxes(cfg){
  const M = 30, idx = cfg.idx;
  let maxCol = 0, maxRow = 0;
  cfg.nodes.forEach(n => { if (n.col > maxCol) maxCol = n.col; if (n.row > maxRow) maxRow = n.row; });
  cfg.nodes.forEach(n => { n._x = M + n.col * (NW + CGAP); n._y = M + n.row * (NH + RGAP); });
  const groups = (cfg.groups || []).map(g => {
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    (g.members || []).forEach(id => { const n = idx[id]; if (!n) return;
      minX = Math.min(minX, n._x); minY = Math.min(minY, n._y); maxX = Math.max(maxX, n._x + NW); maxY = Math.max(maxY, n._y + NH); });
    if (!isFinite(minX)) return null;
    const lt = g.labelTop || 0;
    const x = minX - g.pad, y = minY - g.pad - lt, w = (maxX - minX) + 2 * g.pad, h = (maxY - minY) + 2 * g.pad + lt;
    return { kind: g.kind, label: g.label, x, y, w, h, _area: w * h };
  }).filter(Boolean).sort((a, b) => b._area - a._area);
  let W = M + (maxCol + 1) * NW + maxCol * CGAP + M;
  let H = M + (maxRow + 1) * NH + maxRow * RGAP + M;
  groups.forEach(g => { W = Math.max(W, g.x + g.w + M); H = Math.max(H, g.y + g.h + M); });
  return { W, H, groups };
}
function draw(view){
  const cfg = VIEWS[view];
  NW = cfg.NW; NH = cfg.NH; CGAP = cfg.CGAP; RGAP = cfg.RGAP;
  document.getElementById('legend').innerHTML = cfg.legend;
  document.getElementById('summary').textContent = cfg.summary();
  document.getElementById('panelHead').textContent = cfg.panelHead;
  document.getElementById('roadmapExtras').style.display = (view === 'roadmap') ? '' : 'none';
  board.innerHTML = ''; selEl = null; edgeEls = [];

  if (!cfg.nodes || cfg.nodes.length === 0){
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.innerHTML = (view === 'service')
      ? '<b>서비스 흐름이 아직 없어요.</b><br><code>docs/spec/service-flow.md</code> 에 <b>Groups</b>·<b>Components</b> 표를 채우면 여기에 운영 아키텍처가 그려집니다.'
      : '<b>표시할 모듈이 없어요.</b><br><code>docs/issues/</code> 에 이슈를 추가하세요.';
    board.appendChild(empty);
    detail.innerHTML = '';
    return;
  }

  const dim = cfg.mode === 'boxes' ? posBoxes(cfg) : posDag(cfg);
  const flow = makeFlow(dim.W, dim.H);
  if (dim.groups) dim.groups.forEach(g => {
    const box = document.createElement('div');
    box.className = 'grp ' + g.kind;
    box.style.left = g.x + 'px'; box.style.top = g.y + 'px'; box.style.width = g.w + 'px'; box.style.height = g.h + 'px';
    const lab = document.createElement('div'); lab.className = 'grp-label'; lab.textContent = g.label;
    box.appendChild(lab); flow.appendChild(box);
  });
  cfg.nodes.forEach(n => (n.deps || []).forEach(d => {
    const a = cfg.idx[d]; if (!a) return;          // dangling dep: no edge (flagged on node)
    // edge colour = the SOURCE node's status colour (the box it leaves).
    addEdge(flow._svg, a, n, cfg.sideEdge ? cfg.sideEdge(n) : false, cfg.color ? cfg.color(a) : 'var(--edge)');
  }));
  cfg.nodes.forEach(n => addNode(flow, cfg, n));
  board.appendChild(flow);
  _flowEl = flow; _dim = dim;
  board.appendChild(zoomCtl);
  fitView();
  const first = flow.querySelector('.node');
  if (cfg.nodes[0] && first) selectNode(cfg, cfg.nodes[0], first);
}

/* ===================== NEXT-TASK GUIDE (roadmap-scoped) ===================== */
(function(){
  const active = F.find(f => f.gate === 'active');
  const readyF = F.filter(f => f.ready);
  const label = f => f.id + ' ' + f.title;
  const parts = [];
  if (active) parts.push('진행 중인 ' + label(active) + ' 모듈을 완료');
  if (readyF.length) parts.push('지금 시작 가능한 ' + readyF.map(label).join(', ') + ' 모듈을 병렬 착수');
  const guide = document.getElementById('nextGuide');
  if (guide) guide.textContent = parts.length ? parts.join(' + ') : (DATA.nextTask || '진행할 작업이 없습니다.');
})();

/* ===================== CONTROLS ===================== */
let curView = 'roadmap';
document.querySelectorAll('.tab').forEach(t => {
  t.addEventListener('click', () => {
    if (t.classList.contains('active')) return;
    document.querySelector('.tab.active').classList.remove('active');
    t.classList.add('active'); curView = t.dataset.view; draw(curView);
  });
});
const wrap = document.getElementById('wrap'), toggleBtn = document.getElementById('toggle');
toggleBtn.addEventListener('click', () => {
  wrap.classList.toggle('collapsed');
  toggleBtn.textContent = wrap.classList.contains('collapsed') ? '상세 패널 열기 ▸' : '상세 패널 닫기 ✕';
});
const themeBtn = document.getElementById('theme');
function applyTheme(t){
  document.documentElement.dataset.theme = t;
  themeBtn.textContent = t === 'light' ? '🌙 다크로' : '☀ 라이트로';
  try { localStorage.setItem('rm-theme', t); } catch (e) {}
}
let savedTheme = 'dark';
try { savedTheme = localStorage.getItem('rm-theme') || 'dark'; } catch (e) {}
applyTheme(savedTheme);
themeBtn.addEventListener('click', () => applyTheme(document.documentElement.dataset.theme === 'light' ? 'dark' : 'light'));

document.getElementById('footNote').innerHTML =
  '두 탭은 <b>상호 연결</b> — 「서비스 흐름」에서 부품을 클릭하면 그게 어느 <b>개발 단계(Phase)</b>에서 만들어지는지 패널에 보입니다. ' +
  '캔버스는 <b>드래그로 이동</b>·<b>휠로 확대/축소</b>·<b>⤢로 화면 맞춤</b>. ' +
  '「개발 로드맵」 = <code>docs/issues/</code> · 「서비스 흐름」 = <code>docs/spec/service-flow.md</code>.';

/* ===================== PAN / ZOOM ===================== */
let _flowEl = null, _dim = null, _scale = 1, _tx = 0, _ty = 0;
function applyView(){
  if (_flowEl) _flowEl.style.transform = 'translate(' + _tx + 'px,' + _ty + 'px) scale(' + _scale + ')';
  const lvl = document.getElementById('zlvl');
  if (lvl) lvl.textContent = Math.round(_scale * 100) + '%';
}
function fitView(){
  if (!_dim) return;
  const bw = board.clientWidth, bh = board.clientHeight, pad = 28;
  const s = Math.min(1, (bw - pad) / _dim.W, (bh - pad) / _dim.H);
  _scale = (isFinite(s) && s > 0) ? s : 1;
  _tx = Math.max(14, (bw - _dim.W * _scale) / 2);
  _ty = 14;
  applyView();
}
function zoomAt(mx, my, factor){
  const ns = Math.min(3, Math.max(0.2, _scale * factor));
  _tx = mx - (mx - _tx) * (ns / _scale);
  _ty = my - (my - _ty) * (ns / _scale);
  _scale = ns; applyView();
}

const zoomCtl = document.createElement('div');
zoomCtl.className = 'zoomctl';
zoomCtl.innerHTML =
  '<button id="zout" title="축소">−</button>' +
  '<div class="lvl" id="zlvl">100%</div>' +
  '<button id="zin" title="확대">+</button>' +
  '<button id="zfit" title="화면 맞춤">⤢</button>';
zoomCtl.addEventListener('mousedown', e => e.stopPropagation());
zoomCtl.querySelector('#zin').addEventListener('click', () => zoomAt(board.clientWidth / 2, board.clientHeight / 2, 1.2));
zoomCtl.querySelector('#zout').addEventListener('click', () => zoomAt(board.clientWidth / 2, board.clientHeight / 2, 1 / 1.2));
zoomCtl.querySelector('#zfit').addEventListener('click', fitView);

let _pan = false, _psx = 0, _psy = 0, _ptx = 0, _pty = 0;
board.addEventListener('mousedown', e => {
  if (e.button !== 0) return;
  if (e.target.closest('.node') || e.target.closest('.zoomctl')) return;
  _pan = true; _psx = e.clientX; _psy = e.clientY; _ptx = _tx; _pty = _ty;
  board.classList.add('grabbing');
});
window.addEventListener('mousemove', e => {
  if (!_pan) return;
  _tx = _ptx + (e.clientX - _psx); _ty = _pty + (e.clientY - _psy); applyView();
});
window.addEventListener('mouseup', () => { _pan = false; board.classList.remove('grabbing'); });
board.addEventListener('wheel', e => {
  e.preventDefault();
  const r = board.getBoundingClientRect();
  zoomAt(e.clientX - r.left, e.clientY - r.top, e.deltaY < 0 ? 1.1 : 1 / 1.1);
}, { passive: false });
window.addEventListener('resize', fitView);

draw('roadmap');
</script>
</body>
</html>
HTML_TAIL

echo "roadmap: wrote $OUT"
