#!/bin/bash
# Copy CommMate assets to public directory

set -e

CUSTOM_DIR="custom/assets"
PUBLIC_DIR="public"

echo "📦 Copying CommMate assets..."

# Create directories if they don't exist
mkdir -p "$PUBLIC_DIR/images"
mkdir -p "$PUBLIC_DIR/commmate"

# Copy logos if they exist
if [ -d "$CUSTOM_DIR/images" ]; then
    echo "   → Copying logos..."
    cp -r $CUSTOM_DIR/images/* $PUBLIC_DIR/images/ 2>/dev/null || echo "   ⚠️  No images found in $CUSTOM_DIR/images"
fi

if [ -d "$CUSTOM_DIR/logos" ]; then
    echo "   → Copying additional logos..."
    cp -r $CUSTOM_DIR/logos/* $PUBLIC_DIR/images/ 2>/dev/null || echo "   ⚠️  No logos found in $CUSTOM_DIR/logos"
fi

# Copy favicons if they exist
if [ -d "$CUSTOM_DIR/favicons" ]; then
    echo "   → Copying favicons..."
    cp $CUSTOM_DIR/favicons/* $PUBLIC_DIR/ 2>/dev/null || echo "   ⚠️  No favicons found in $CUSTOM_DIR/favicons"
fi

echo "✅ CommMate assets copied successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Add your logo files to custom/assets/images/"
echo "   2. Add your favicons to custom/assets/favicons/"
echo "   3. Run this script again to update assets"

