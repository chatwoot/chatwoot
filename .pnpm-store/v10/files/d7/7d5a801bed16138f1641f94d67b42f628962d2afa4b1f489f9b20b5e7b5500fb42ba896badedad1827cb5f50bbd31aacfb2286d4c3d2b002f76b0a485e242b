import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const PACKAGE_JSON = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'package.json'), 'utf8'));
export const VERSION = PACKAGE_JSON.version;
//# sourceMappingURL=package.js.map