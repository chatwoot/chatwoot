import { createRequire } from 'node:module';
import { PLUGINS_HAVE_DEV } from './util.js';
const require = createRequire(import.meta.url);
export const resolvedSupportPluginsCollect = (ctx) => {
    const plugins = ctx.supportPlugins.map(p => `'${p.id}': () => import(${JSON.stringify(require.resolve(`${p.moduleName}/collect${process.env.HISTOIRE_DEV && PLUGINS_HAVE_DEV.includes(p.moduleName) ? '-dev' : ''}`, {
        paths: [ctx.root, import.meta.url],
    }))})`);
    return `export const collectSupportPlugins = {
    ${plugins.join(',\n  ')}
  }`;
};
