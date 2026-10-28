#!/usr/bin/env bash
# Build the store-ready .iq package (release build) for every product in manifest.xml.
# No dependency on the garmin-dev Claude/Cursor plugin.
set -euo pipefail

source "$(dirname "$0")/lib-sdk.sh"

IQ="bin/wodtimer.iq"

# -e reads <iq:products> from the manifest; passing -d would narrow it to one device.
echo "Packaging all manifest products with $SDK_BIN/monkeyc ..." >&2
"$SDK_BIN/monkeyc" -e -r -w -f monkey.jungle -o "$IQ" -y developer_key
echo "Package: $IQ (upload at https://apps.garmin.com/en-US/developer/upload)" >&2
