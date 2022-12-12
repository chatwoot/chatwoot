'use strict';
const EventEmitter = require('events');
const path = require('path');
const os = require('os');
const pMap = require('p-map');
const arrify = require('arrify');
const globby = require('globby');
const hasGlob = require('has-glob');
const cpFile = require('cp-file');
const junk = require('junk');
const pFilter = require('p-filter');
const CpyError = require('./cpy-error');

const defaultOptions = {
	ignoreJunk: true
};

class SourceFile {
	constructor(relativePath, path) {
		this.path = path;
		this.relativePath = relativePath;
		Object.freeze(this);
	}

	get name() {
		return path.basename(this.relativePath);
	}

	get nameWithoutExtension() {
		return path.basename(this.relativePath, path.extname(this.relativePath));
	}

	get extension() {
		return path.extname(this.relativePath).slice(1);
	}
}

const preprocessSourcePath = (source, options) => path.resolve(options.cwd ? options.cwd : process.cwd(), source);

const preprocessDestinationPath = (source, destination, options) => {
	let basename = path.basename(source);

	if (typeof options.rename === 'string') {
		basename = options.rename;
	} else if (typeof options.rename === 'function') {
		basename = options.rename(basename);
	}

	if (options.cwd) {
		destination = path.resolve(options.cwd, destination);
	}

	if (options.parents) {
		const dirname = path.dirname(source);
		const parsedDirectory = path.parse(dirname);
		return path.join(destination, dirname.replace(parsedDirectory.root, path.sep), basename);
	}

	return path.join(destination, basename);
};

module.exports = (source, destination, {
	concurrency = (os.cpus().length || 1) * 2,
	...options
} = {}) => {
	const progressEmitter = new EventEmitter();

	options = {
		...defaultOptions,
		...options
	};

	const promise = (async () => {
		source = arrify(source);

		if (source.length === 0 || !destination) {
			throw new CpyError('`source` and `destination` required');
		}

		const copyStatus = new Map();
		let completedFiles = 0;
		let completedSize = 0;

		let files;
		try {
			files = await globby(source, options);

			if (options.ignoreJunk) {
				files = files.filter(file => junk.not(path.basename(file)));
			}
		} catch (error) {
			throw new CpyError(`Cannot glob \`${source}\`: ${error.message}`, error);
		}

		if (files.length === 0 && !hasGlob(source)) {
			throw new CpyError(`Cannot copy \`${source}\`: the file doesn't exist`);
		}

		let sources = files.map(sourcePath => new SourceFile(sourcePath, preprocessSourcePath(sourcePath, options)));

		if (options.filter !== undefined) {
			const filteredSources = await pFilter(sources, options.filter, {concurrency: 1024});
			sources = filteredSources;
		}

		if (sources.length === 0) {
			progressEmitter.emit('progress', {
				totalFiles: 0,
				percent: 1,
				completedFiles: 0,
				completedSize: 0
			});
		}

		const fileProgressHandler = event => {
			const fileStatus = copyStatus.get(event.src) || {written: 0, percent: 0};

			if (fileStatus.written !== event.written || fileStatus.percent !== event.percent) {
				completedSize -= fileStatus.written;
				completedSize += event.written;

				if (event.percent === 1 && fileStatus.percent !== 1) {
					completedFiles++;
				}

				copyStatus.set(event.src, {
					written: event.written,
					percent: event.percent
				});

				progressEmitter.emit('progress', {
					totalFiles: files.length,
					percent: completedFiles / files.length,
					completedFiles,
					completedSize
				});
			}
		};

		return pMap(sources, async source => {
			const to = preprocessDestinationPath(source.relativePath, destination, options);

			try {
				await cpFile(source.path, to, options).on('progress', fileProgressHandler);
			} catch (error) {
				throw new CpyError(`Cannot copy from \`${source.relativePath}\` to \`${to}\`: ${error.message}`, error);
			}

			return to;
		}, {concurrency});
	})();

	promise.on = (...arguments_) => {
		progressEmitter.on(...arguments_);
		return promise;
	};

	return promise;
};
