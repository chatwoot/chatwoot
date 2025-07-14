import process from 'node:process';
import path from 'node:path';
import fs from 'node:fs';
import commonPathPrefix from 'common-path-prefix';
import {packageDirectorySync} from 'pkg-dir';

const {env, cwd} = process;

const isWritable = path => {
	try {
		fs.accessSync(path, fs.constants.W_OK);
		return true;
	} catch {
		return false;
	}
};

function useDirectory(directory, options) {
	if (options.create) {
		fs.mkdirSync(directory, {recursive: true});
	}

	return directory;
}

function getNodeModuleDirectory(directory) {
	const nodeModules = path.join(directory, 'node_modules');

	if (
		!isWritable(nodeModules)
			&& (fs.existsSync(nodeModules) || !isWritable(path.join(directory)))
	) {
		return;
	}

	return nodeModules;
}

export default function findCacheDirectory(options = {}) {
	if (env.CACHE_DIR && !['true', 'false', '1', '0'].includes(env.CACHE_DIR)) {
		return useDirectory(path.join(env.CACHE_DIR, options.name), options);
	}

	let {cwd: directory = cwd(), files} = options;

	if (files) {
		if (!Array.isArray(files)) {
			throw new TypeError(`Expected \`files\` option to be an array, got \`${typeof files}\`.`);
		}

		directory = commonPathPrefix(files.map(file => path.resolve(directory, file)));
	}

	directory = packageDirectorySync({cwd: directory});

	if (!directory) {
		return;
	}

	const nodeModules = getNodeModuleDirectory(directory);
	if (!nodeModules) {
		return;
	}

	return useDirectory(path.join(directory, 'node_modules', '.cache', options.name), options);
}
