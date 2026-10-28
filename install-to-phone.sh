#!/bin/bash
# Build "100 Days" and install it on a plugged-in iPhone (free Personal Team signing).
#
#   ./install-to-phone.sh
#
# Works over Wi-Fi once the phone has been paired; it does not need to be plugged in.
#
# Prerequisites, once each:
#   1. iPhone paired: plug it in, unlock, tap "Trust This Computer" (after that, Wi-Fi is fine).
#   2. iPhone: Settings > Privacy & Security > Developer Mode > On (reboots the phone).
#   3. A provisioning profile for this bundle ID. Xcode creates one the first time you
#      run the app on the device, and renews it when it expires (free profiles last 7 days).
#      If signing fails with "No profiles ... were found", open the project in Xcode,
#      pick the phone as the destination and press Run once; then this script works again.
set -euo pipefail
cd "$(dirname "$0")"

# The team is the OU of the signing certificate, NOT the id in its common name:
# "Apple Development: you@example.com (G6H5P3DS85)" has OU=2VZDDH4DF6, and the team
# is the OU. Resolve it from the certificate rather than hardcoding the wrong one.
TEAM="${TEAM:-$(security find-certificate -a -c "Apple Development" -p 2>/dev/null \
  | openssl x509 -noout -subject 2>/dev/null \
  | sed -n 's/.*OU=\([A-Z0-9]*\).*/\1/p' | head -1)}"
if [ -z "${TEAM:-}" ]; then
  echo "No 'Apple Development' certificate found in the keychain." >&2
  echo "Open Xcode, sign in under Settings > Accounts, and run the app on the phone once." >&2
  exit 1
fi
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

echo "==> Building and signing (team $TEAM)"
xcodebuild -project Hundred.xcodeproj -scheme Hundred -configuration Debug \
  -destination "platform=iOS,id=$UDID" \
  -derivedDataPath build/device \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
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
