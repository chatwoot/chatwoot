import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import globalDirectory from 'global-directory';
import isPathInside from 'is-path-inside';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const isInstalledGlobally = (() => {
	try {
		return (
			isPathInside(__dirname, globalDirectory.yarn.packages)
			|| isPathInside(__dirname, fs.realpathSync(globalDirectory.npm.packages))
		);
	} catch {
		return false;
	}
})();

export default isInstalledGlobally;
