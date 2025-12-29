/**
 * Script para reemplazar todos los logos de Chatwoot con los logos de Hablia
 * 
 * Uso:
 *   1. Coloca tus archivos fuente en una carpeta 'logos-source/':
 *      - logo.svg (logo principal modo claro)
 *      - logo-dark.svg (logo principal modo oscuro)
 *      - logo-thumbnail.svg (logo miniatura 512x512)
 *      - logo.png (logo PNG de alta resolución, al menos 512x512)
 * 
 *   2. Ejecuta: node scripts/replace-logos.js
 */

const fs = require('fs');
const path = require('path');

// Verificar si sharp está instalado
let sharp;
try {
  sharp = require('sharp');
} catch (e) {
  console.error('Error: sharp no está instalado.');
  console.error('Por favor ejecuta: npm install --save-dev sharp');
  process.exit(1);
}

const SOURCE_DIR = path.join(__dirname, '..', 'logos-source');
const PUBLIC_BRAND_ASSETS = path.join(__dirname, '..', 'public', 'brand-assets');
const WIDGET_ASSETS = path.join(__dirname, '..', 'app', 'javascript', 'widget', 'assets', 'images');
const DASHBOARD_ASSETS = path.join(__dirname, '..', 'app', 'javascript', 'dashboard', 'assets', 'images');
const DESIGN_SYSTEM_ASSETS = path.join(__dirname, '..', 'app', 'javascript', 'design-system', 'images');
const PUBLIC_DIR = path.join(__dirname, '..', 'public');

// Tamaños de favicon necesarios
const FAVICON_SIZES = [16, 32, 96, 512];
const APPLE_ICON_SIZES = [57, 60, 72, 76, 114, 120, 144, 152, 180];
const ANDROID_ICON_SIZES = [36, 48, 72, 96, 144, 192];
const MS_ICON_SIZES = [70, 144, 150, 310];

async function copyFile(src, dest) {
  try {
    await fs.promises.mkdir(path.dirname(dest), { recursive: true });
    await fs.promises.copyFile(src, dest);
    console.log(`✓ Copiado: ${dest}`);
  } catch (error) {
    console.error(`✗ Error copiando ${src} a ${dest}:`, error.message);
  }
}

async function resizeImage(src, dest, size) {
  try {
    await fs.promises.mkdir(path.dirname(dest), { recursive: true });
    await sharp(src)
      .resize(size, size, {
        fit: 'contain',
        background: { r: 255, g: 255, b: 255, alpha: 0 }
      })
      .png()
      .toFile(dest);
    console.log(`✓ Generado: ${dest} (${size}x${size})`);
  } catch (error) {
    console.error(`✗ Error generando ${dest}:`, error.message);
  }
}

async function generateBadgeFavicon(src, dest, size) {
  try {
    await fs.promises.mkdir(path.dirname(dest), { recursive: true });
    // Crear un favicon con badge (círculo rojo pequeño en la esquina)
    const image = sharp(src).resize(size, size);
    const svg = Buffer.from(`
      <svg width="${size}" height="${size}">
        <circle cx="${size - size/4}" cy="${size/4}" r="${size/6}" fill="#ff0000"/>
      </svg>
    `);
    
    await sharp({
      create: {
        width: size,
        height: size,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      }
    })
      .composite([
        { input: await image.png().toBuffer(), top: 0, left: 0 },
        { input: svg, top: 0, left: 0 }
      ])
      .png()
      .toFile(dest);
    console.log(`✓ Generado badge favicon: ${dest} (${size}x${size})`);
  } catch (error) {
    console.error(`✗ Error generando badge favicon ${dest}:`, error.message);
  }
}

async function main() {
  console.log('🎨 Iniciando reemplazo de logos...\n');

  // Verificar que existen los archivos fuente
  const sourceFiles = {
    logo: path.join(SOURCE_DIR, 'logo.svg'),
    logoDark: path.join(SOURCE_DIR, 'logo-dark.svg'),
    logoThumbnail: path.join(SOURCE_DIR, 'logo-thumbnail.svg'),
    logoPng: path.join(SOURCE_DIR, 'logo.png')
  };

  for (const [name, filepath] of Object.entries(sourceFiles)) {
    if (!fs.existsSync(filepath)) {
      console.error(`✗ Archivo fuente no encontrado: ${filepath}`);
      console.error(`  Por favor coloca ${name} en la carpeta logos-source/`);
      return;
    }
  }

  console.log('✓ Todos los archivos fuente encontrados\n');

  // 1. Copiar logos SVG principales
  console.log('📋 Copiando logos SVG...');
  await copyFile(sourceFiles.logo, path.join(PUBLIC_BRAND_ASSETS, 'logo.svg'));
  await copyFile(sourceFiles.logoDark, path.join(PUBLIC_BRAND_ASSETS, 'logo_dark.svg'));
  await copyFile(sourceFiles.logoThumbnail, path.join(PUBLIC_BRAND_ASSETS, 'logo_thumbnail.svg'));
  
  // Logos del design system
  await copyFile(sourceFiles.logoThumbnail, path.join(DESIGN_SYSTEM_ASSETS, 'logo-thumbnail.svg'));
  
  // Logo del widget
  await copyFile(sourceFiles.logoThumbnail, path.join(WIDGET_ASSETS, 'logo.svg'));
  await copyFile(sourceFiles.logoThumbnail, path.join(DASHBOARD_ASSETS, 'bubble-logo.svg'));

  // 2. Generar PNGs del design system desde SVG
  console.log('\n📋 Generando PNGs del design system...');
  const logoPngBuffer = await sharp(sourceFiles.logo).png().toBuffer();
  await fs.promises.writeFile(path.join(DESIGN_SYSTEM_ASSETS, 'logo.png'), logoPngBuffer);
  console.log(`✓ Generado: ${path.join(DESIGN_SYSTEM_ASSETS, 'logo.png')}`);
  
  const logoDarkPngBuffer = await sharp(sourceFiles.logoDark).png().toBuffer();
  await fs.promises.writeFile(path.join(DESIGN_SYSTEM_ASSETS, 'logo-dark.png'), logoDarkPngBuffer);
  console.log(`✓ Generado: ${path.join(DESIGN_SYSTEM_ASSETS, 'logo-dark.png')}`);

  // 3. Generar favicons desde PNG
  console.log('\n📋 Generando favicons...');
  for (const size of FAVICON_SIZES) {
    await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, `favicon-${size}x${size}.png`), size);
    await generateBadgeFavicon(sourceFiles.logoPng, path.join(PUBLIC_DIR, `favicon-badge-${size}x${size}.png`), size);
  }

  // 4. Generar iconos de Apple
  console.log('\n📋 Generando iconos de Apple...');
  for (const size of APPLE_ICON_SIZES) {
    await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, `apple-icon-${size}x${size}.png`), size);
  }
  // Copiar para apple-touch-icon
  await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, 'apple-touch-icon.png'), 180);
  await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, 'apple-icon.png'), 180);
  await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, 'apple-icon-precomposed.png'), 180);
  await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, 'apple-touch-icon-precomposed.png'), 180);

  // 5. Generar iconos de Android
  console.log('\n📋 Generando iconos de Android...');
  for (const size of ANDROID_ICON_SIZES) {
    await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, `android-icon-${size}x${size}.png`), size);
  }

  // 6. Generar iconos de Microsoft
  console.log('\n📋 Generando iconos de Microsoft...');
  for (const size of MS_ICON_SIZES) {
    await resizeImage(sourceFiles.logoPng, path.join(PUBLIC_DIR, `ms-icon-${size}x${size}.png`), size);
  }

  console.log('\n✅ ¡Todos los logos han sido reemplazados exitosamente!');
  console.log('\n📝 Nota: Asegúrate de actualizar también las referencias en:');
  console.log('   - app.json (línea 6)');
  console.log('   - config/installation_config.yml');
  console.log('   - enterprise/config/premium_installation_config.yml');
}

main().catch(console.error);

