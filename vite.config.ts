import fs from 'fs';
import path from 'path';
import { defineConfig, loadEnv, type Plugin } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';

const I18N_DIR = path.resolve('./app/javascript/dashboard/i18n');
const DEV_LOCALES_MODULE = '\0dev-locales';

// The dev server serves `dashboard/i18n` with only English plus the locales
// listed in DEV_LOCALES, instead of importing every locale file.
const devLocales = (locales: string[]): Plugin => ({
  name: 'chatwoot:dev-locales',
  apply: 'serve',
  enforce: 'pre',
  resolveId: id => (id === I18N_DIR ? DEV_LOCALES_MODULE : null),
  load(id) {
    if (id !== DEV_LOCALES_MODULE) return null;

    const imports = locales.map(locale => {
      const dir = path.join(I18N_DIR, 'locale', locale);
      if (!fs.existsSync(dir)) {
        throw new Error(`Unknown locale in DEV_LOCALES: ${locale}`);
      }
      return `import ${locale} from '${dir}';`;
    });
    return `${imports.join('\n')}\nexport default { ${locales.join(', ')} };`;
  },
});

export default defineConfig(({ mode }) => {
  const { DEV_LOCALES = '' } = loadEnv(mode, process.cwd(), 'DEV_');
  const extraLocales = DEV_LOCALES.split(',')
    .map(locale => locale.trim())
    .filter(Boolean);

  return {
    plugins: [
      ruby(),
      vue(vueOptions),
      yaml(),
      ...(extraLocales.includes('all')
        ? []
        : [devLocales([...new Set(['en', ...extraLocales])])]),
    ],
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        },
      },
    },
    resolve: { alias: aliases },
    // Transform the dashboard module graph at startup, while Rails boots,
    // instead of on the first browser request.
    server: { warmup: { clientFiles: ['./entrypoints/dashboard.js'] } },
  };
});
