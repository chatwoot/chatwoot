import { spawnSync } from 'node:child_process';
import { writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { getCacheDir } from '../util/cache.js';
const PAGER_CONTENT_FILE_PATH = join(getCacheDir(), 'pager-content.txt');
export async function pager(content) {
    if (process.platform === 'win32') {
        return pagerForWindows(content);
    }
    else {
        return pagerForPOSIX(content);
    }
}
async function pagerForWindows(content) {
    await writeFile(PAGER_CONTENT_FILE_PATH, content, 'utf-8');
    try {
        spawnSync('more', [PAGER_CONTENT_FILE_PATH], { shell: true, stdio: 'inherit' });
    }
    catch (e) {
        console.error('Failed to execute `more` command. Please install `more` command.');
        throw e;
    }
}
async function pagerForPOSIX(content) {
    await writeFile(PAGER_CONTENT_FILE_PATH, content, 'utf-8');
    try {
        spawnSync('less', ['-R', PAGER_CONTENT_FILE_PATH], { shell: true, stdio: 'inherit' });
    }
    catch (e) {
        console.error('Failed to execute `less` command. Please install `less` command.');
        throw e;
    }
}
//# sourceMappingURL=pager.js.map