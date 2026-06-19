#!/usr/bin/env bash
# package-lib.sh -- shared packaging implementation for cosherpa plugin builds.
#
# Source-only. The public interface is:
#   package_copy_workflow_assets <dest-plugin-root>
#   package_normalize_release_tree <plugin-root>

PACKAGE_SOURCE_WORKFLOW_DIR="workflows-coSherpa"
PACKAGE_INSTALL_WORKFLOW_DIR="workflows-coSherpa"

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

package_install_rel() {
  local rel="$1"
  case "$rel" in
    "$PACKAGE_SOURCE_WORKFLOW_DIR"/*)
      printf '%s/%s' "$PACKAGE_INSTALL_WORKFLOW_DIR" "${rel#"$PACKAGE_SOURCE_WORKFLOW_DIR/"}"
      ;;
    "$PACKAGE_SOURCE_WORKFLOW_DIR")
      printf '%s' "$PACKAGE_INSTALL_WORKFLOW_DIR"
      ;;
    *)
      printf '%s' "$rel"
      ;;
  esac
}

package_rewrite_installed_file() {
  local file="$1"
  LC_ALL=C grep -Iq . "$file" 2>/dev/null || return 0
  # The source template and installed projects both use the less-colliding
  # workflows-coSherpa/ harness root.
  sed "s#${PACKAGE_SOURCE_WORKFLOW_DIR}/#${PACKAGE_INSTALL_WORKFLOW_DIR}/#g" "$file" > "$file.tmp" &&
    mv -f "$file.tmp" "$file"
}

package_copy_workflow_assets() {
  local plugin_dest="$1"
  local dest="$plugin_dest/assets/workflow"
  local line dest_rel file

  rm -rf "$dest"
  mkdir -p "$dest"

  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    if [[ "$line" == */ ]]; then
      [ -d "$REPO_ROOT/$line" ] || continue
      dest_rel="$(package_install_rel "$line")"
      mkdir -p "$dest/$dest_rel"
      cp -R "$REPO_ROOT/$line/." "$dest/$dest_rel/"
    else
      [ -f "$REPO_ROOT/$line" ] || { echo "[FAIL] manifest path missing: $line" >&2; return 2; }
      dest_rel="$(package_install_rel "$line")"
      mkdir -p "$dest/$(dirname "$dest_rel")"
      cp "$REPO_ROOT/$line" "$dest/$dest_rel"
    fi
  done < "$WORKFLOW_ROOT/workflow-manifest.txt"

  mkdir -p "$dest/$PACKAGE_INSTALL_WORKFLOW_DIR"
  cp -R "$WORKFLOW_ROOT/skills" "$dest/$PACKAGE_INSTALL_WORKFLOW_DIR/skills"

  while IFS= read -r -d '' file; do
    package_rewrite_installed_file "$file"
  done < <(find "$dest" -type f -print0)
}
