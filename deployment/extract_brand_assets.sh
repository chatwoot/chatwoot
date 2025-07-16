#!/bin/sh

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <url to zip file with favicons>. See https://github.com/fazer-ai/chatwoot/blob/main/CUSTOM_BRANDING.md for more info."
  exit 1
fi

URL="$1"
TEMP_DIR=$(mktemp -d)
ZIP_FILE="$TEMP_DIR/downloaded_favicons.zip"
EXTRACT_DIR="$TEMP_DIR/extracted_favicons"
TARGET_DIR="public"

EXPECTED_FILES="
android-icon-36x36.png
android-icon-48x48.png
android-icon-72x72.png
android-icon-96x96.png
android-icon-144x144.png
android-icon-192x192.png
apple-icon-57x57.png
apple-icon-60x60.png
apple-icon-72x72.png
apple-icon-76x76.png
apple-icon-114x114.png
apple-icon-120x120.png
apple-icon-144x144.png
apple-icon-152x152.png
apple-icon-180x180.png
apple-icon.png
apple-icon-precomposed.png
apple-touch-icon.png
apple-touch-icon-precomposed.png
favicon-16x16.png
favicon-32x32.png
favicon-96x96.png
favicon-512x512.png
favicon-badge-16x16.png
favicon-badge-32x32.png
favicon-badge-96x96.png
ms-icon-70x70.png
ms-icon-144x144.png
ms-icon-150x150.png
ms-icon-310x310.png
"

cleanup() {
  echo "Cleaning up temporary files..."
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Downloading zip file from $URL..."
if wget -q -O "$ZIP_FILE" "$URL"; then
  echo "Download successful."
else
  echo "Error: Failed to download file from $URL"
  exit 1
fi

echo "Creating extraction directory: $EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

echo "Unzipping $ZIP_FILE to $EXTRACT_DIR..."
if unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR"; then
  echo "Unzip successful."
else
  echo "Error: Failed to unzip $ZIP_FILE"
  exit 1
fi

echo "Checking for expected files..."
MISSING_FILES=0
for filename in $EXPECTED_FILES; do
  if ! find "$EXTRACT_DIR" -name "$filename" -print | grep -q .; then
    echo "Warning: Expected file '$filename' not found in the zip archive."
    MISSING_FILES=$((MISSING_FILES + 1))
  fi
done

if [ "$MISSING_FILES" -gt 0 ]; then
  echo "$MISSING_FILES expected file(s) were not found in the zip archive."
fi

echo "Moving extracted files to $TARGET_DIR/..."
mv "$EXTRACT_DIR"/* "$TARGET_DIR/" 2>/dev/null || true

echo "Process completed."
