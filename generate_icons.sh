#!/bin/bash

# This script generates all icon variations for Chatwoot branding
# Requires ImageMagick to be installed: brew install imagemagick

# Source logo
SOURCE_LOGO="public/brand-assets/chatscommerce/logo.png"

# Create output directory if it doesn't exist
mkdir -p public/brand-assets/generated

# Determine which ImageMagick command to use (convert for v6, magick for v7+)
if command -v magick &> /dev/null; then
    CONVERT_CMD="magick"
    echo "Using ImageMagick v7+ with 'magick' command"
else
    CONVERT_CMD="convert"
    echo "Using ImageMagick v6 with 'convert' command"
fi

# Generate favicon variations
$CONVERT_CMD "$SOURCE_LOGO" -resize 16x16 public/favicon-16x16.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 32x32 public/favicon-32x32.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 96x96 public/favicon-96x96.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 512x512 public/favicon-512x512.png

# Generate favicon.ico (contains multiple sizes)
$CONVERT_CMD "$SOURCE_LOGO" -resize 16x16 public/favicon-16x16.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 32x32 public/favicon-32x32.png
$CONVERT_CMD public/favicon-16x16.png public/favicon-32x32.png public/favicon.ico

# Generate favicon badge variations (you might want to add a badge or notification dot)
$CONVERT_CMD "$SOURCE_LOGO" -resize 16x16 public/favicon-badge-16x16.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 32x32 public/favicon-badge-32x32.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 96x96 public/favicon-badge-96x96.png

# Generate Apple icon variations
$CONVERT_CMD "$SOURCE_LOGO" -resize 57x57 public/apple-icon-57x57.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 60x60 public/apple-icon-60x60.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 72x72 public/apple-icon-72x72.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 76x76 public/apple-icon-76x76.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 114x114 public/apple-icon-114x114.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 120x120 public/apple-icon-120x120.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 144x144 public/apple-icon-144x144.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 152x152 public/apple-icon-152x152.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 180x180 public/apple-icon-180x180.png
cp public/apple-icon-180x180.png public/apple-icon.png
cp public/apple-icon-180x180.png public/apple-icon-precomposed.png
cp public/apple-icon-180x180.png public/apple-touch-icon.png
cp public/apple-icon-180x180.png public/apple-touch-icon-precomposed.png

# Generate Android icon variations
$CONVERT_CMD "$SOURCE_LOGO" -resize 36x36 public/android-icon-36x36.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 48x48 public/android-icon-48x48.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 72x72 public/android-icon-72x72.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 96x96 public/android-icon-96x96.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 144x144 public/android-icon-144x144.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 192x192 public/android-icon-192x192.png

# Generate Microsoft icon variations
$CONVERT_CMD "$SOURCE_LOGO" -resize 70x70 public/ms-icon-70x70.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 144x144 public/ms-icon-144x144.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 150x150 public/ms-icon-150x150.png
$CONVERT_CMD "$SOURCE_LOGO" -resize 310x310 public/ms-icon-310x310.png

# Create browserconfig.xml file for Microsoft browsers
cat > public/browserconfig.xml << EOL
<?xml version="1.0" encoding="utf-8"?>
<browserconfig>
  <msapplication>
    <tile>
      <square70x70logo src="/ms-icon-70x70.png"/>
      <square150x150logo src="/ms-icon-150x150.png"/>
      <square310x310logo src="/ms-icon-310x310.png"/>
      <TileColor>#1f93ff</TileColor>
    </tile>
  </msapplication>
</browserconfig>
EOL

echo "All icon variations have been generated successfully!" 
