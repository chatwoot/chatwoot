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

echo "Flattening all files from extracted archive…"
find "$EXTRACT_DIR" -type f -exec mv -f {} "$TARGET_DIR/" \;

echo "Process completed."
