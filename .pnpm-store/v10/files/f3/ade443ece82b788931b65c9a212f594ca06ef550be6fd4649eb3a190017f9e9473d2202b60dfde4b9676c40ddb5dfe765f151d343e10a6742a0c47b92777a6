import process from 'node:process';
import fs from 'node:fs';
import path from 'node:path';
import fastGlob from 'fast-glob';
import gitIgnore from 'ignore';
import slash from 'slash';
import {toPath, isNegativePattern} from './utilities.js';

const ignoreFilesGlobOptions = {
	ignore: [
		'**/node_modules',
		'**/flow-typed',
		'**/coverage',
		'**/.git',
	],
	absolute: true,
	dot: true,
};

export const GITIGNORE_FILES_PATTERN = '**/.gitignore';

const applyBaseToPattern = (pattern, base) => isNegativePattern(pattern)
	? '!' + path.posix.join(base, pattern.slice(1))
	: path.posix.join(base, pattern);

const parseIgnoreFile = (file, cwd) => {
	const base = slash(path.relative(cwd, path.dirname(file.filePath)));

	return file.content
		.split(/\r?\n/)
		.filter(line => line && !line.startsWith('#'))
		.map(pattern => applyBaseToPattern(pattern, base));
};

const toRelativePath = (fileOrDirectory, cwd) => {
	cwd = slash(cwd);
	if (path.isAbsolute(fileOrDirectory)) {
		if (slash(fileOrDirectory).startsWith(cwd)) {
			return path.relative(cwd, fileOrDirectory);
		}

		throw new Error(`Path ${fileOrDirectory} is not in cwd ${cwd}`);
	}

	return fileOrDirectory;
};

const getIsIgnoredPredicate = (files, cwd) => {
	const patterns = files.flatMap(file => parseIgnoreFile(file, cwd));
	const ignores = gitIgnore().add(patterns);

	return fileOrDirectory => {
		fileOrDirectory = toPath(fileOrDirectory);
		fileOrDirectory = toRelativePath(fileOrDirectory, cwd);
		return fileOrDirectory ? ignores.ignores(slash(fileOrDirectory)) : false;
	};
};

const normalizeOptions = (options = {}) => ({
	cwd: toPath(options.cwd) || process.cwd(),
	suppressErrors: Boolean(options.suppressErrors),
	deep: typeof options.deep === 'number' ? options.deep : Number.POSITIVE_INFINITY,
});

export const isIgnoredByIgnoreFiles = async (patterns, options) => {
	const {cwd, suppressErrors, deep} = normalizeOptions(options);

	const paths = await fastGlob(patterns, {cwd, suppressErrors, deep, ...ignoreFilesGlobOptions});

	const files = await Promise.all(
		paths.map(async filePath => ({
			filePath,
			content: await fs.promises.readFile(filePath, 'utf8'),
		})),
	);

	return getIsIgnoredPredicate(files, cwd);
};

export const isIgnoredByIgnoreFilesSync = (patterns, options) => {
	const {cwd, suppressErrors, deep} = normalizeOptions(options);

	const paths = fastGlob.sync(patterns, {cwd, suppressErrors, deep, ...ignoreFilesGlobOptions});

	const files = paths.map(filePath => ({
		filePath,
		content: fs.readFileSync(filePath, 'utf8'),
	}));

	return getIsIgnoredPredicate(files, cwd);
};

export const isGitIgnored = options => isIgnoredByIgnoreFiles(GITIGNORE_FILES_PATTERN, options);
export const isGitIgnoredSync = options => isIgnoredByIgnoreFilesSync(GITIGNORE_FILES_PATTERN, options);
