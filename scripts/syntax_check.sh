#!/usr/bin/env bash
#
# Compile every attribute in ecl/ with the real ECL compiler. This is the
# fastest honest feedback loop for this repo: no cluster, no data, but it
# catches every type and syntax error.
#
#   ./scripts/syntax_check.sh            # everything
#   ./scripts/syntax_check.sh ecl/Common # one folder
#
# Requires the HPCC client tools (eclcc) on PATH:
#   https://hpccsystems.com/download/

set -uo pipefail
cd "$(dirname "$0")/.."

if ! command -v eclcc >/dev/null 2>&1; then
  echo "syntax_check: eclcc not found on PATH." >&2
  echo "Install the HPCC Systems client tools, or run ./scripts/lint.sh instead." >&2
  exit 127
fi

target="${1:-ecl}"
fail=0

while IFS= read -r file; do
  if eclcc -syntax -I ecl "$file" 2>&1 | tee /tmp/eclcc.$$ | grep -q .; then
    echo "--- $file"
    cat /tmp/eclcc.$$
    grep -q 'error' /tmp/eclcc.$$ && fail=1
  else
    echo "ok  $file"
  fi
  rm -f /tmp/eclcc.$$
done < <(find "$target" -name '*.ecl' | sort)

if (( fail )); then
  echo
  echo "syntax_check: FAIL"
  exit 1
fi

echo
echo "syntax_check: OK"
