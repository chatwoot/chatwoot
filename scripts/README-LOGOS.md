# 📋 Guía para Reemplazar Logos de Chatwoot con Logos de Hablia

## Preparación

### 1. Instalar dependencia necesaria

```bash
pnpm add -D sharp
```

### 2. Preparar tus archivos fuente

Crea una carpeta `logos-source/` en la raíz del proyecto y coloca ahí tus archivos:

```
logos-source/
├── logo.svg              # Logo principal modo claro
├── logo-dark.svg         # Logo principal modo oscuro  
├── logo-thumbnail.svg    # Logo miniatura (512x512) para favicon
└── logo.png              # Logo PNG de alta resolución (mínimo 512x512)
```

**Requisitos:**
- Los SVG deben estar optimizados
- El PNG debe ser de alta calidad, preferiblemente 512x512 o mayor
- El logo-thumbnail.svg será usado como base para todos los favicons e iconos

### 3. Ejecutar el script

```bash
node scripts/replace-logos.js
```

El script hará automáticamente:
- ✅ Copiar los logos SVG a todas las ubicaciones necesarias
- ✅ Generar todos los tamaños de favicon (16x16, 32x32, 96x96, 512x512)
- ✅ Generar favicons con badge para notificaciones
- ✅ Generar todos los iconos de Apple (57x57 hasta 180x180)
- ✅ Generar todos los iconos de Android (36x36 hasta 192x192)
- ✅ Generar todos los iconos de Microsoft/Windows
- ✅ Generar PNGs para el design system

## Actualización Manual de Referencias

Después de ejecutar el script, actualiza estas referencias manualmente:

### app.json
```json
"logo": "https://tu-dominio.com/brand-assets/logo_thumbnail.svg"
```

### Archivos de configuración
Los archivos `config/installation_config.yml` y `enterprise/config/premium_installation_config.yml` 
ya tienen las rutas correctas (`/brand-assets/logo.svg`), pero verifica que estén bien.

## Verificación

Después de reemplazar los logos:
1. Verifica que los logos se vean correctamente en:
   - Dashboard principal
   - Página de login
   - Widget de chat
   - Favicon del navegador
   - App móvil (si aplica)

2. Revisa que los favicons funcionen:
   - Abre el dashboard en el navegador
   - Verifica la pestaña del navegador muestra tu logo
   - Verifica que cuando hay notificaciones, el badge se muestra

## Notas

- Los logos deben tener fondo transparente para mejor visualización
- Los SVG deben estar optimizados para web
- Si tus logos tienen colores específicos, asegúrate de que funcionen tanto en modo claro como oscuro

