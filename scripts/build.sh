#!/usr/bin/env bash
# Build the debug .prg with the local Connect IQ SDK.
# No dependency on the garmin-dev Claude/Cursor plugin.
set -euo pipefail

source "$(dirname "$0")/lib-sdk.sh"

echo "Building for $DEVICE with $SDK_BIN/monkeyc ..." >&2
exec "$SDK_BIN/monkeyc" -f monkey.jungle -o "$PRG" -y developer_key -d "$DEVICE"
