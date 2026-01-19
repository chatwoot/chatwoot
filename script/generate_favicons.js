const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const inputSvg = path.join(__dirname, '..', 'public', 'brand-assets', 'logo_thumbnail.svg');
const outputDir = path.join(__dirname, '..', 'public');

// Sizes to generate
const sizes = [
  { size: 16, name: 'favicon-16x16.png' },
  { size: 32, name: 'favicon-32x32.png' },
  { size: 96, name: 'favicon-96x96.png' },
  { size: 192, name: 'android-icon-192x192.png' },
  { size: 512, name: 'android-icon-512x512.png' },
  { size: 57, name: 'apple-icon-57x57.png' },
  { size: 60, name: 'apple-icon-60x60.png' },
  { size: 72, name: 'apple-icon-72x72.png' },
  { size: 76, name: 'apple-icon-76x76.png' },
  { size: 114, name: 'apple-icon-114x114.png' },
  { size: 120, name: 'apple-icon-120x120.png' },
  { size: 144, name: 'apple-icon-144x144.png' },
  { size: 152, name: 'apple-icon-152x152.png' },
  { size: 180, name: 'apple-icon-180x180.png' },
  { size: 36, name: 'android-icon-36x36.png' },
  { size: 48, name: 'android-icon-48x48.png' },
  { size: 72, name: 'android-icon-72x72.png' }, // duplicate, but ok
  { size: 96, name: 'android-icon-96x96.png' },
  { size: 144, name: 'android-icon-144x144.png' },
  { size: 70, name: 'ms-icon-70x70.png' },
  { size: 144, name: 'ms-icon-144x144.png' },
  { size: 150, name: 'ms-icon-150x150.png' },
  { size: 310, name: 'ms-icon-310x310.png' },
];

async function generateFavicons() {
  for (const { size, name } of sizes) {
    const outputPath = path.join(outputDir, name);
    await sharp(inputSvg)
      .resize(size, size)
      .png({ quality: 100 })
      .toFile(outputPath);
    console.log(`Generated ${name}`);
  }

  // Generate favicon.ico from 32x32
  const icoPath = path.join(outputDir, 'favicon.ico');
  await sharp(path.join(outputDir, 'favicon-32x32.png'))
    .toFile(icoPath);
  console.log('Generated favicon.ico');

  // Copy apple-touch-icon.png from 180x180
  const appleTouchPath = path.join(outputDir, 'apple-touch-icon.png');
  fs.copyFileSync(path.join(outputDir, 'apple-icon-180x180.png'), appleTouchPath);
  console.log('Generated apple-touch-icon.png');

  // Copy apple-touch-icon-precomposed.png
  const appleTouchPrecomposedPath = path.join(outputDir, 'apple-touch-icon-precomposed.png');
  fs.copyFileSync(appleTouchPath, appleTouchPrecomposedPath);
  console.log('Generated apple-touch-icon-precomposed.png');

  // Copy apple-icon.png from 57x57
  const appleIconPath = path.join(outputDir, 'apple-icon.png');
  fs.copyFileSync(path.join(outputDir, 'apple-icon-57x57.png'), appleIconPath);
  console.log('Generated apple-icon.png');

  // Generate favicon-badge versions (if needed, but for now skip)
}

generateFavicons().catch(console.error);