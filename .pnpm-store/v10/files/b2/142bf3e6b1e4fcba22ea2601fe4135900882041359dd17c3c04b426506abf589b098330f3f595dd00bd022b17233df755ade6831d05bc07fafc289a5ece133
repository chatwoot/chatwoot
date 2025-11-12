import { tmpdir } from 'node:os';
import { join } from 'node:path';
import findCacheDirectory from 'find-cache-dir';
import { VERSION } from '../cli/package.js';
/**
 * Get the path of cache directory for eslint-interactive.
 */
export function getCacheDir() {
    // If package.json exists in the parent directory of cwd,then node_modules/.cache/eslint-interactive
    // under that directory is set as the cache directory.
    // If it does not exist, the OS's temporary directory is used.
    const packageCacheDir = findCacheDirectory({ name: 'eslint-interactive' }) ?? join(tmpdir(), 'eslint-interactive');
    return join(packageCacheDir, VERSION);
}
//# sourceMappingURL=cache.js.map