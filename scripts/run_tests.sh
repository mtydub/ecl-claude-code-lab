#!/usr/bin/env bash
#
# Run the ECL test suite on a cluster. Needs the client tools configured
# against a running HPCC instance (`ecl --version`, and an ~/.ecl/ecl.ini
# or --server / --username flags).
#
#   ./scripts/run_tests.sh              # hthor, no data required
#   ./scripts/run_tests.sh thor
#
# The tests use inline fixtures only, so they do not depend on
# BWR_SprayLanding having been run.

set -euo pipefail
cd "$(dirname "$0")/.."

target="${1:-hthor}"

if ! command -v ecl >/dev/null 2>&1; then
  echo "run_tests: 'ecl' not found on PATH." >&2
  echo "Install the HPCC Systems client tools: https://hpccsystems.com/download/" >&2
  exit 127
fi

echo "Running ECL tests on $target ..."
ecl run "$target" ecl/Tests/BWR_RunAllTests.ecl -I ecl --wait=600000
