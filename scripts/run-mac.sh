#!/bin/sh
# Builds the Mac app and installs it where macOS will load its system extension.
# With SIP on, an extension loads only from /Applications and is replaced only when its build number changes.
# Usage: DEVELOPMENT_TEAM=ABCDE12345 scripts/run-mac.sh
set -eu
: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your Apple Developer team ID}"
cd "$(dirname "$0")/.."
xcodegen generate
xcodebuild -scheme AppRouteMac -configuration Debug -derivedDataPath .derivedData \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CURRENT_PROJECT_VERSION="$(date +%s)" build
osascript -e 'quit app id "app.harena.AppRoute.Mac"' 2>/dev/null || true
rm -rf /Applications/AppRoute.app
cp -R .derivedData/Build/Products/Debug/AppRoute.app /Applications/AppRoute.app
open /Applications/AppRoute.app
