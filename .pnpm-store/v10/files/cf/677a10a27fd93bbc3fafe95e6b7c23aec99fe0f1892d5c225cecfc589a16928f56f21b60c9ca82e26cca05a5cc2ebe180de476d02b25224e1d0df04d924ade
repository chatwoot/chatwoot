import process from 'node:process';
import path from 'node:path';
import url from 'node:url';
import pathKey from 'path-key';

export function npmRunPath(options = {}) {
	const {
		cwd = process.cwd(),
		path: path_ = process.env[pathKey()],
		execPath = process.execPath,
	} = options;

	let previous;
	const cwdString = cwd instanceof URL ? url.fileURLToPath(cwd) : cwd;
	let cwdPath = path.resolve(cwdString);
	const result = [];

	while (previous !== cwdPath) {
		result.push(path.join(cwdPath, 'node_modules/.bin'));
		previous = cwdPath;
		cwdPath = path.resolve(cwdPath, '..');
	}

	// Ensure the running `node` binary is used.
	result.push(path.resolve(cwdString, execPath, '..'));

	return [...result, path_].join(path.delimiter);
}

export function npmRunPathEnv({env = process.env, ...options} = {}) {
	env = {...env};

	const path = pathKey({env});
	options.path = env[path];
	env[path] = npmRunPath(options);

	return env;
}
