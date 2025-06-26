#!/bin/bash

# Icon Generation Script
# This script generates all favicons and app icons from public/brand-assets/logo.png

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed.${NC}"
    echo "Please install ImageMagick:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "  CentOS/RHEL: sudo yum install ImageMagick"
    exit 1
fi

# Define paths
LOGO_SOURCE="public/brand-assets/logo.png"
PUBLIC_DIR="public"
OLD_DIR="public/old"

# Check if logo source exists
if [ ! -f "$LOGO_SOURCE" ]; then
    echo -e "${RED}Error: Logo source file not found at $LOGO_SOURCE${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Starting icon generation from $LOGO_SOURCE${NC}"

# Create old directory if it doesn't exist
mkdir -p "$OLD_DIR"

# Define all icon specifications
# Format: "filename:size:description"
declare -a ICONS=(
    # Android Icons
    "android-icon-36x36.png:36x36:Android Icon 36x36"
    "android-icon-48x48.png:48x48:Android Icon 48x48"
    "android-icon-72x72.png:72x72:Android Icon 72x72"
    "android-icon-96x96.png:96x96:Android Icon 96x96"
    "android-icon-144x144.png:144x144:Android Icon 144x144"
    "android-icon-192x192.png:192x192:Android Icon 192x192"
    
    # Apple Icons
    "apple-icon-57x57.png:57x57:Apple Icon 57x57"
    "apple-icon-60x60.png:60x60:Apple Icon 60x60"
    "apple-icon-72x72.png:72x72:Apple Icon 72x72"
    "apple-icon-76x76.png:76x76:Apple Icon 76x76"
    "apple-icon-114x114.png:114x114:Apple Icon 114x114"
    "apple-icon-120x120.png:120x120:Apple Icon 120x120"
    "apple-icon-144x144.png:144x144:Apple Icon 144x144"
    "apple-icon-152x152.png:152x152:Apple Icon 152x152"
    "apple-icon-180x180.png:180x180:Apple Icon 180x180"
    "apple-icon-precomposed.png:180x180:Apple Icon Precomposed"
    "apple-icon.png:180x180:Apple Icon"
    "apple-touch-icon-precomposed.png:180x180:Apple Touch Icon Precomposed"
    "apple-touch-icon.png:180x180:Apple Touch Icon"
    
    # Favicons
    "favicon-16x16.png:16x16:Favicon 16x16"
    "favicon-32x32.png:32x32:Favicon 32x32"
    "favicon-96x96.png:96x96:Favicon 96x96"
    "favicon-512x512.png:512x512:Favicon 512x512"
    
    # Favicon Badges (notification badges)
    "favicon-badge-16x16.png:16x16:Favicon Badge 16x16"
    "favicon-badge-32x32.png:32x32:Favicon Badge 32x32"
    "favicon-badge-96x96.png:96x96:Favicon Badge 96x96"
    
    # Microsoft Icons
    "ms-icon-70x70.png:70x70:Microsoft Icon 70x70"
    "ms-icon-144x144.png:144x144:Microsoft Icon 144x144"
    "ms-icon-150x150.png:150x150:Microsoft Icon 150x150"
    "ms-icon-310x310.png:310x310:Microsoft Icon 310x310"
)

echo -e "${YELLOW}📦 Moving existing icons to $OLD_DIR${NC}"

# Move existing icons to old directory
moved_count=0
for icon_spec in "${ICONS[@]}"; do
    IFS=':' read -ra PARTS <<< "$icon_spec"
    filename="${PARTS[0]}"
    
    if [ -f "$PUBLIC_DIR/$filename" ]; then
        mv "$PUBLIC_DIR/$filename" "$OLD_DIR/"
        ((moved_count++))
        echo "  ✓ Moved $filename"
    fi
done

echo -e "${GREEN}✅ Moved $moved_count existing icons to old directory${NC}"

echo -e "${YELLOW}🎨 Generating new icons from logo...${NC}"

# Generate new icons
generated_count=0
failed_count=0

for icon_spec in "${ICONS[@]}"; do
    IFS=':' read -ra PARTS <<< "$icon_spec"
    filename="${PARTS[0]}"
    size="${PARTS[1]}"
    description="${PARTS[2]}"
    
    echo "  🔧 Generating $filename ($size)..."
    
    # Generate the icon using ImageMagick
    if convert "$LOGO_SOURCE" -resize "$size" -quality 95 "$PUBLIC_DIR/$filename"; then
        ((generated_count++))
        echo "    ✅ $description"
    else
        ((failed_count++))
        echo -e "    ${RED}❌ Failed to generate $filename${NC}"
    fi
done

# Generate favicon.ico (multi-size ICO file)
echo "  🔧 Generating favicon.ico..."
if convert "$LOGO_SOURCE" \
    \( -clone 0 -resize 16x16 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 64x64 \) \
    -delete 0 "$PUBLIC_DIR/favicon.ico"; then
    ((generated_count++))
    echo "    ✅ Multi-size favicon.ico"
else
    ((failed_count++))
    echo -e "    ${RED}❌ Failed to generate favicon.ico${NC}"
fi

# Summary
echo
echo -e "${BLUE}📊 Generation Summary:${NC}"
echo -e "  ${GREEN}✅ Successfully generated: $generated_count icons${NC}"
if [ $failed_count -gt 0 ]; then
    echo -e "  ${RED}❌ Failed to generate: $failed_count icons${NC}"
fi
echo -e "  📁 Old icons moved to: $OLD_DIR"
echo

if [ $failed_count -eq 0 ]; then
    echo -e "${GREEN}🎉 All icons generated successfully!${NC}"
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Test the new icons in your application"
    echo "  2. If satisfied, you can delete the old icons: rm -rf $OLD_DIR"
    echo "  3. Commit the new icons to your repository"
else
    echo -e "${YELLOW}⚠️  Some icons failed to generate. Please check the errors above.${NC}"
fi

echo
echo -e "${BLUE}🔗 Icon files generated:${NC}"
for icon_spec in "${ICONS[@]}"; do
    IFS=':' read -ra PARTS <<< "$icon_spec"
    filename="${PARTS[0]}"
    size="${PARTS[1]}"
    
    if [ -f "$PUBLIC_DIR/$filename" ]; then
        file_size=$(du -h "$PUBLIC_DIR/$filename" | cut -f1)
        echo "  ✓ $filename ($size) - $file_size"
    fi
done

# Check if favicon.ico was created
if [ -f "$PUBLIC_DIR/favicon.ico" ]; then
    file_size=$(du -h "$PUBLIC_DIR/favicon.ico" | cut -f1)
    echo "  ✓ favicon.ico (multi-size) - $file_size"
fi 