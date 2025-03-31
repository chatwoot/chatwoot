import path from 'node:path';
import { fileURLToPath } from 'node:url';
// Resolve an absolute path to e.g. node_modules/.pnpm/histoire@0.11.7_vite@3.2.4/node_modules/histoire/dist/node/vendors/controls.js
// https://github.com/histoire-dev/histoire/issues/282
export const __dirname = path.dirname(fileURLToPath(import.meta.url));
// https://github.com/vitejs/vite/issues/9661
const alias = {
    '@histoire/vendors/vue': path.resolve(__dirname, '../vendors/vue.js'),
    '@histoire/controls': path.resolve(__dirname, '../vendors/controls.js'),
};
export function getInjectedImport(request) {
    let id = request;
    if (alias[id]) {
        id = alias[id];
    }
    return JSON.stringify(id);
}
