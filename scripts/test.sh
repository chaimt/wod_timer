#!/usr/bin/env bash
# Compile the test binary (monkeyc -t) and run it in the simulator (monkeydo -t).
# The simulator must already be running: start it with `connectiq` from the
# SDK bin directory, or run `task deploy-simulator` (non-test build) first and
# leave the simulator window open.
set -euo pipefail

source "$(dirname "$0")/lib-sdk.sh"

TEST_PRG="bin/wodtimer-test.prg"
TEST_DEVICE="${TEST_DEVICE:-$DEVICE}"

echo "Building unit tests for $TEST_DEVICE with $SDK_BIN/monkeyc ..." >&2
"$SDK_BIN/monkeyc" -f monkey.jungle -o "$TEST_PRG" -y developer_key -d "$TEST_DEVICE" -t

echo "Running tests: $SDK_BIN/monkeydo $TEST_PRG $TEST_DEVICE -t ${TEST_NAME:-}" >&2
if [ -n "${TEST_NAME:-}" ]; then
  exec "$SDK_BIN/monkeydo" "$TEST_PRG" "$TEST_DEVICE" -t "$TEST_NAME"
else
  exec "$SDK_BIN/monkeydo" "$TEST_PRG" "$TEST_DEVICE" -t
fi
