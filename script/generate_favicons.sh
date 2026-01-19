#!/bin/bash

INPUT_SVG="public/brand-assets/logo_thumbnail.svg"
OUTPUT_DIR="public"

# Function to generate PNG
generate_png() {
    local size=$1
    local name=$2
    convert "$INPUT_SVG" -resize "${size}x${size}" -background transparent "$OUTPUT_DIR/$name"
    echo "Generated $name"
}

# Generate all PNG sizes
generate_png 16 "favicon-16x16.png"
generate_png 32 "favicon-32x32.png"
generate_png 96 "favicon-96x96.png"
generate_png 192 "android-icon-192x192.png"
generate_png 512 "android-icon-512x512.png"
generate_png 57 "apple-icon-57x57.png"
generate_png 60 "apple-icon-60x60.png"
generate_png 72 "apple-icon-72x72.png"
generate_png 76 "apple-icon-76x76.png"
generate_png 114 "apple-icon-114x114.png"
generate_png 120 "apple-icon-120x120.png"
generate_png 144 "apple-icon-144x144.png"
generate_png 152 "apple-icon-152x152.png"
generate_png 180 "apple-icon-180x180.png"
generate_png 36 "android-icon-36x36.png"
generate_png 48 "android-icon-48x48.png"
generate_png 72 "android-icon-72x72.png"
generate_png 96 "android-icon-96x96.png"
generate_png 144 "android-icon-144x144.png"
generate_png 70 "ms-icon-70x70.png"
generate_png 144 "ms-icon-144x144.png"
generate_png 150 "ms-icon-150x150.png"
generate_png 310 "ms-icon-310x310.png"

# Generate favicon.ico from 32x32
convert "$OUTPUT_DIR/favicon-32x32.png" "$OUTPUT_DIR/favicon.ico"
echo "Generated favicon.ico"

# Copy apple-touch-icon.png
cp "$OUTPUT_DIR/apple-icon-180x180.png" "$OUTPUT_DIR/apple-touch-icon.png"
echo "Generated apple-touch-icon.png"

# Copy apple-touch-icon-precomposed.png
cp "$OUTPUT_DIR/apple-touch-icon.png" "$OUTPUT_DIR/apple-touch-icon-precomposed.png"
echo "Generated apple-touch-icon-precomposed.png"

# Copy apple-icon.png
cp "$OUTPUT_DIR/apple-icon-57x57.png" "$OUTPUT_DIR/apple-icon.png"
echo "Generated apple-icon.png"

echo "Favicon generation complete!"