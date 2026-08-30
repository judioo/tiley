#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

PROJECT="Tiley.xcodeproj"
SCHEME="Tiley"
CONFIGURATION="Release"
ARCHIVE_PATH="${ARCHIVE_PATH:-build/Tiley.xcarchive}"
# Display name shown in the Finder, menu bar, and Login Items. Override to
# tell installs apart (e.g. APP_DISPLAY_NAME="Tiley Dev"). Default: Tiley.
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-Tiley}"
APP_NAME="${APP_NAME:-$APP_DISPLAY_NAME.app}"
INSTALL_DIR="/Applications"
INSTALLED_APP_PATH="$INSTALL_DIR/$APP_NAME"

mkdir -p build

if pgrep -x "Tiley" >/dev/null 2>&1; then
  echo "Tiley is running. Quitting app..."
  osascript -e 'tell application "Tiley" to quit' >/dev/null 2>&1 || true

  for _ in {1..20}; do
    if ! pgrep -x "Tiley" >/dev/null 2>&1; then
      break
    fi
    sleep 0.5
  done

  if pgrep -x "Tiley" >/dev/null 2>&1; then
    echo "Tiley did not quit in time. Sending TERM..."
    pkill -TERM -x "Tiley" || true
  fi
fi

if [[ -d "$INSTALLED_APP_PATH" ]]; then
  echo "Removing existing app: $INSTALLED_APP_PATH"
  rm -rf "$INSTALLED_APP_PATH"
fi

echo "Cleaning previous archive: $ARCHIVE_PATH"
rm -rf "$ARCHIVE_PATH"

echo "Building archive (display name: $APP_DISPLAY_NAME)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  "INFOPLIST_KEY_CFBundleDisplayName=$APP_DISPLAY_NAME" \
  archive

# The archive always produces Tiley.app (PRODUCT_NAME is unchanged so the
# executable, bundle id, and debug-coordination logic stay stable); only the
# installed bundle is renamed to the chosen display name.
ARCHIVED_APP_PATH="$ARCHIVE_PATH/Products/Applications/Tiley.app"
if [[ ! -d "$ARCHIVED_APP_PATH" ]]; then
  echo "Archived app not found at: $ARCHIVED_APP_PATH"
  exit 1
fi

echo "Copying app to $INSTALLED_APP_PATH"
cp -R "$ARCHIVED_APP_PATH" "$INSTALLED_APP_PATH"

echo "Launching $APP_NAME"
open "$INSTALLED_APP_PATH"

echo "Done: $INSTALLED_APP_PATH"
