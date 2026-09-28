#!/usr/bin/env bash
#
# House style checks for the ECL in this repo. Pure bash, so it runs in CI
# and on a laptop with no HPCC client tools installed.
#
#   ./scripts/lint.sh
#
# Rules
#   1. An attribute file must EXPORT a definition named after the file.
#      Files named BWR_* are builder window runs and are exempt.
#   2. Every file starts with a /** block comment.
#   3. No tabs, no trailing whitespace, no lines over 100 characters.

set -uo pipefail
cd "$(dirname "$0")/.."

MAX_LINE=100
fail=0

note() { printf '%s:%s: %s\n' "$1" "$2" "$3"; fail=1; }

while IFS= read -r file; do
  base="$(basename "$file" .ecl)"

  # 1. EXPORT name matches filename
  if [[ "$base" != BWR_* ]]; then
    if ! grep -Eq "^[[:space:]]*EXPORT[[:space:]]+${base}[[:space:]]*(\(|:=)" "$file"; then
      note "$file" 1 "no 'EXPORT $base' found (rule 1)"
    fi
  fi

  # 2. header comment
  if [[ "$(head -c 3 "$file")" != "/**" ]]; then
    note "$file" 1 "file should open with a /** header comment (rule 2)"
  fi

  # 3. whitespace and width
  while IFS= read -r hit; do
    note "$file" "${hit%%:*}" "tab character (rule 3)"
  done < <(grep -n $'\t' "$file" | cut -d: -f1 | sed 's/$/:/')

  while IFS= read -r ln; do
    note "$file" "$ln" "trailing whitespace (rule 3)"
  done < <(grep -n '[[:space:]]$' "$file" | cut -d: -f1)

  while IFS= read -r ln; do
    note "$file" "$ln" "line longer than ${MAX_LINE} characters (rule 3)"
  done < <(awk -v m="$MAX_LINE" 'length($0) > m { print NR }' "$file")

done < <(find ecl -name '*.ecl' | sort)

if (( fail )); then
  echo
  echo "lint: FAIL"
  exit 1
fi

echo "lint: OK ($(find ecl -name '*.ecl' | wc -l | tr -d ' ') files)"
