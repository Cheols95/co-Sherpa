#!/usr/bin/env bash
# _portable.sh -- small cross-platform helpers for Bash 3.2+.
#
# Target shell matrix: macOS system Bash 3.2, Git Bash on Windows, WSL/Linux.
# Keep this file source-only and dependency-light.

portable_version_sort() {
  if sort -V </dev/null >/dev/null 2>&1; then
    sort -V
    return
  fi

  awk '
    {
      rest = $0
      key = ""
      while (match(rest, /[0-9]+/)) {
        prefix = substr(rest, 1, RSTART - 1)
        num = substr(rest, RSTART, RLENGTH)
        norm = num
        sub(/^0+/, "", norm)
        if (norm == "") norm = "0"
        key = key prefix sprintf("%08d:%s:%08d", length(norm), norm, length(num))
        rest = substr(rest, RSTART + RLENGTH)
      }
      print key rest "\t" $0
    }
  ' | LC_ALL=C sort | sed 's/^[^	]*	//'
}

portable_mktemp_file() {
  mktemp 2>/dev/null || mktemp "${TMPDIR:-/tmp}/ironman.XXXXXX"
}

portable_mktemp_dir() {
  mktemp -d 2>/dev/null || mktemp -d "${TMPDIR:-/tmp}/ironman.XXXXXX"
}

portable_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    "$@"
  fi
}
