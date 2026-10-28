#!/usr/bin/env bash
# Build the debug .prg and run it in the Connect IQ simulator.
# Starts the simulator (connectiq) in the background if it is not running yet.
set -euo pipefail

source "$(dirname "$0")/lib-sdk.sh"

echo "Building for $DEVICE with $SDK_BIN/monkeyc ..." >&2
"$SDK_BIN/monkeyc" -f monkey.jungle -o "$PRG" -y developer_key -d "$DEVICE"

sim_running() {
  pgrep -f "ConnectIQ.*\.app|connectiq.*simulator|MonkeyMotion" >/dev/null 2>&1
}

if ! sim_running; then
  echo "Starting the Connect IQ simulator ..." >&2
  "$SDK_BIN/connectiq" >/dev/null 2>&1 &
  # Wait for the simulator to come up (up to ~30s).
  for _ in $(seq 1 30); do
    sleep 1
    sim_running && break
  done
fi

# Give the simulator one more beat before pushing the app.
sleep 2
echo "Running: $SDK_BIN/monkeydo $PRG $DEVICE" >&2
exec "$SDK_BIN/monkeydo" "$PRG" "$DEVICE"
