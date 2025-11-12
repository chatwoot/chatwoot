import fs from 'node:fs';
import nodePath from 'node:path';
import merge2 from 'merge2';
import fastGlob from 'fast-glob';
import dirGlob from 'dir-glob';
import {
	GITIGNORE_FILES_PATTERN,
	isIgnoredByIgnoreFiles,
	isIgnoredByIgnoreFilesSync,
} from './ignore.js';
import {FilterStream, toPath, isNegativePattern} from './utilities.js';

const assertPatternsInput = patterns => {
	if (patterns.some(pattern => typeof pattern !== 'string')) {
		throw new TypeError('Patterns must be a string or an array of strings');
	}
};

const toPatternsArray = patterns => {
	patterns = [...new Set([patterns].flat())];
	assertPatternsInput(patterns);
	return patterns;
};

const checkCwdOption = options => {
	if (!options.cwd) {
		return;
	}

	let stat;
	try {
		stat = fs.statSync(options.cwd);
	} catch {
		return;
	}

	if (!stat.isDirectory()) {
		throw new Error('The `cwd` option must be a path to a directory');
	}
};

const normalizeOptions = (options = {}) => {
	options = {
		...options,
		ignore: options.ignore || [],
		expandDirectories: options.expandDirectories === undefined
			? true
			: options.expandDirectories,
		cwd: toPath(options.cwd),
	};

	checkCwdOption(options);

	return options;
};

const normalizeArguments = fn => async (patterns, options) => fn(toPatternsArray(patterns), normalizeOptions(options));
const normalizeArgumentsSync = fn => (patterns, options) => fn(toPatternsArray(patterns), normalizeOptions(options));

const getIgnoreFilesPatterns = options => {
	const {ignoreFiles, gitignore} = options;

	const patterns = ignoreFiles ? toPatternsArray(ignoreFiles) : [];
	if (gitignore) {
		patterns.push(GITIGNORE_FILES_PATTERN);
	}

	return patterns;
};

const getFilter = async options => {
	const ignoreFilesPatterns = getIgnoreFilesPatterns(options);
	return createFilterFunction(
		ignoreFilesPatterns.length > 0 && await isIgnoredByIgnoreFiles(ignoreFilesPatterns, options),
	);
};

const getFilterSync = options => {
	const ignoreFilesPatterns = getIgnoreFilesPatterns(options);
	return createFilterFunction(
		ignoreFilesPatterns.length > 0 && isIgnoredByIgnoreFilesSync(ignoreFilesPatterns, options),
	);
};

const createFilterFunction = isIgnored => {
	const seen = new Set();

	return fastGlobResult => {
		const path = fastGlobResult.path || fastGlobResult;
		const pathKey = nodePath.normalize(path);
		const seenOrIgnored = seen.has(pathKey) || (isIgnored && isIgnored(path));
		seen.add(pathKey);
		return !seenOrIgnored;
	};
};

const unionFastGlobResults = (results, filter) => results.flat().filter(fastGlobResult => filter(fastGlobResult));
const unionFastGlobStreams = (streams, filter) => merge2(streams).pipe(new FilterStream(fastGlobResult => filter(fastGlobResult)));

const convertNegativePatterns = (patterns, options) => {
	const tasks = [];

	while (patterns.length > 0) {
		const index = patterns.findIndex(pattern => isNegativePattern(pattern));

		if (index === -1) {
			tasks.push({patterns, options});
			break;
		}

		const ignorePattern = patterns[index].slice(1);

		for (const task of tasks) {
			task.options.ignore.push(ignorePattern);
		}

		if (index !== 0) {
			tasks.push({
				patterns: patterns.slice(0, index),
				options: {
					...options,
					ignore: [
						...options.ignore,
						ignorePattern,
					],
				},
			});
		}

		patterns = patterns.slice(index + 1);
	}

	return tasks;
};

const getDirGlobOptions = (options, cwd) => ({
	...(cwd ? {cwd} : {}),
	...(Array.isArray(options) ? {files: options} : options),
});

const generateTasks = async (patterns, options) => {
	const globTasks = convertNegativePatterns(patterns, options);

	const {cwd, expandDirectories} = options;

	if (!expandDirectories) {
		return globTasks;
	}

	const patternExpandOptions = getDirGlobOptions(expandDirectories, cwd);
	const ignoreExpandOptions = cwd ? {cwd} : undefined;

	return Promise.all(
		globTasks.map(async task => {
			let {patterns, options} = task;

			[
				patterns,
				options.ignore,
			] = await Promise.all([
				dirGlob(patterns, patternExpandOptions),
				dirGlob(options.ignore, ignoreExpandOptions),
			]);

			return {patterns, options};
		}),
	);
};

const generateTasksSync = (patterns, options) => {
	const globTasks = convertNegativePatterns(patterns, options);

	const {cwd, expandDirectories} = options;

	if (!expandDirectories) {
		return globTasks;
	}

	const patternExpandOptions = getDirGlobOptions(expandDirectories, cwd);
	const ignoreExpandOptions = cwd ? {cwd} : undefined;

	return globTasks.map(task => {
		let {patterns, options} = task;
		patterns = dirGlob.sync(patterns, patternExpandOptions);
		options.ignore = dirGlob.sync(options.ignore, ignoreExpandOptions);
		return {patterns, options};
	});
};

export const globby = normalizeArguments(async (patterns, options) => {
	const [
		tasks,
		filter,
	] = await Promise.all([
		generateTasks(patterns, options),
		getFilter(options),
	]);
	const results = await Promise.all(tasks.map(task => fastGlob(task.patterns, task.options)));

	return unionFastGlobResults(results, filter);
});

export const globbySync = normalizeArgumentsSync((patterns, options) => {
	const tasks = generateTasksSync(patterns, options);
	const filter = getFilterSync(options);
	const results = tasks.map(task => fastGlob.sync(task.patterns, task.options));

	return unionFastGlobResults(results, filter);
});

export const globbyStream = normalizeArgumentsSync((patterns, options) => {
	const tasks = generateTasksSync(patterns, options);
	const filter = getFilterSync(options);
	const streams = tasks.map(task => fastGlob.stream(task.patterns, task.options));

	return unionFastGlobStreams(streams, filter);
});

export const isDynamicPattern = normalizeArgumentsSync(
	(patterns, options) => patterns.some(pattern => fastGlob.isDynamicPattern(pattern, options)),
);

export const generateGlobTasks = normalizeArguments(generateTasks);
export const generateGlobTasksSync = normalizeArgumentsSync(generateTasksSync);

export {
	isGitIgnored,
	isGitIgnoredSync,
} from './ignore.js';
