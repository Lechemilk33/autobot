#!/bin/bash
# Build "100 Days" and install it on a plugged-in iPhone (free Personal Team signing).
#
#   ./install-to-phone.sh
#
# Prerequisites, once each:
#   1. iPhone plugged in and unlocked, "Trust This Computer" tapped.
#   2. iPhone: Settings > Privacy & Security > Developer Mode > On (reboots the phone).
#   3. Xcode > Settings > Accounts > + > Apple ID > sign in (needed so Xcode can
#      create the free provisioning profile; the keychain certificate alone is not enough).
set -euo pipefail
cd "$(dirname "$0")"

TEAM="${TEAM:-G6H5P3DS85}"          # Personal Team for ryansilvas33@gmail.com
BUNDLE="${BUNDLE:-com.lechemilk33.hundred}"

echo "==> Looking for a connected iPhone"
TMP=$(mktemp -t hundreddev)
xcrun devicectl list devices --json-output "$TMP" >/dev/null 2>&1 || true
read -r UDID DEVNAME <<<"$(python3 - "$TMP" <<'PYEOF'
import json, sys
try:
    devs = json.load(open(sys.argv[1]))["result"]["devices"]
except Exception:
    sys.exit(0)
for d in devs:
    hw = d.get("hardwareProperties", {})
    conn = d.get("connectionProperties", {})
    if hw.get("platform") != "iOS":
        continue
    if conn.get("pairingState") != "paired":
        continue
    print(hw.get("udid", ""), d.get("deviceProperties", {}).get("name", "iPhone"))
    break
PYEOF
)"
rm -f "$TMP"
if [ -z "${UDID:-}" ]; then
  echo "No paired iPhone found." >&2
  echo "Plug it in, unlock it, tap Trust This Computer, then run:" >&2
  echo "  xcrun devicectl list devices" >&2
  exit 1
fi
echo "    $DEVNAME ($UDID)"

echo "==> Building and signing"
xcodebuild -project Hundred.xcodeproj -scheme Hundred -configuration Debug \
  -destination "platform=iOS,id=$UDID" \
  -derivedDataPath build/device \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE" \
  build

APP=$(find build/device/Build/Products -maxdepth 2 -name "Hundred.app" | head -1)
echo "==> Installing $APP"
xcrun devicectl device install app --device "$UDID" "$APP"

echo
echo "Done. Launch '100 Days' from the home screen."
echo "First run only: Settings > General > VPN & Device Management > trust your Apple ID."
echo "Free signing expires after 7 days - just run this script again (your data is kept)."
