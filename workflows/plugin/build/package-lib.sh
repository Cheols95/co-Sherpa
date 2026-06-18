#!/usr/bin/env bash
# package-lib.sh -- shared packaging implementation for cosherpa plugin builds.
#
# Source-only. The public interface is:
#   package_copy_workflow_assets <dest-plugin-root>
#   package_normalize_release_tree <plugin-root>

package_normalize_lf_if_needed() {
  local file="$1" tmp cr
  LC_ALL=C grep -Iq . "$file" 2>/dev/null || return 0
  cr=$(printf '\r')
  if LC_ALL=C grep -q "$cr" "$file" 2>/dev/null; then
    tmp=$(mktemp 2>/dev/null || mktemp "${TMPDIR:-/tmp}/cosherpa.XXXXXX") || return 1
    tr -d '\r' < "$file" > "$tmp"
    mv -f "$tmp" "$file"
  fi
}

package_normalize_release_tree() {
  local root="$1" file
  [ -d "$root" ] || return 0

  find "$root" -type d -exec chmod 0755 {} +
  find "$root" -type f -exec chmod 0644 {} +

  while IFS= read -r -d '' file; do
    package_normalize_lf_if_needed "$file"
  done < <(find "$root" -type f -print0)

  while IFS= read -r -d '' file; do
    chmod 0755 "$file"
  done < <(
    find "$root" -type f \
      \( -name '*.sh' -o -name '*.gates.sh' -o -name '*.next-task.sh' -o -path '*/bin/*' \) \
      -print0
  )
}

package_copy_workflow_assets() {
  local plugin_dest="$1"
  local dest="$plugin_dest/assets/workflow"
  local line

  rm -rf "$dest"
  mkdir -p "$dest"

  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    if [[ "$line" == */ ]]; then
      [ -d "$REPO_ROOT/$line" ] || continue
      mkdir -p "$dest/$line"
      cp -R "$REPO_ROOT/$line/." "$dest/$line/"
    else
      [ -f "$REPO_ROOT/$line" ] || { echo "[FAIL] manifest path missing: $line" >&2; return 2; }
      mkdir -p "$dest/$(dirname "$line")"
      cp "$REPO_ROOT/$line" "$dest/$line"
    fi
  done < "$WORKFLOW_ROOT/workflow-manifest.txt"

  mkdir -p "$dest/workflows"
  cp -R "$WORKFLOW_ROOT/skills" "$dest/workflows/skills"
}
