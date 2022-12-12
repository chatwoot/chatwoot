'use strict';
const path = require('path');
const {constants: fsConstants} = require('fs');
const pEvent = require('p-event');
const CpFileError = require('./cp-file-error');
const fs = require('./fs');
const ProgressEmitter = require('./progress-emitter');

const cpFileAsync = async (source, destination, options, progressEmitter) => {
	let readError;
	const stat = await fs.stat(source);
	progressEmitter.size = stat.size;

	const read = await fs.createReadStream(source);
	await fs.makeDir(path.dirname(destination));
	const write = fs.createWriteStream(destination, {flags: options.overwrite ? 'w' : 'wx'});
	read.on('data', () => {
		progressEmitter.written = write.bytesWritten;
	});
	read.once('error', error => {
		readError = new CpFileError(`Cannot read from \`${source}\`: ${error.message}`, error);
		write.end();
	});

	let updateStats = false;
	try {
		const writePromise = pEvent(write, 'close');
		read.pipe(write);
		await writePromise;
		progressEmitter.written = progressEmitter.size;
		updateStats = true;
	} catch (error) {
		if (options.overwrite || error.code !== 'EEXIST') {
			throw new CpFileError(`Cannot write to \`${destination}\`: ${error.message}`, error);
		}
	}

	if (readError) {
		throw readError;
	}

	if (updateStats) {
		const stats = await fs.lstat(source);

		return Promise.all([
			fs.utimes(destination, stats.atime, stats.mtime),
			fs.chmod(destination, stats.mode),
			fs.chown(destination, stats.uid, stats.gid)
		]);
	}
};

const cpFile = (source, destination, options) => {
	if (!source || !destination) {
		return Promise.reject(new CpFileError('`source` and `destination` required'));
	}

	options = {
		overwrite: true,
		...options
	};

	const progressEmitter = new ProgressEmitter(path.resolve(source), path.resolve(destination));
	const promise = cpFileAsync(source, destination, options, progressEmitter);
	promise.on = (...args) => {
		progressEmitter.on(...args);
		return promise;
	};

	return promise;
};

module.exports = cpFile;

const checkSourceIsFile = (stat, source) => {
	if (stat.isDirectory()) {
		throw Object.assign(new CpFileError(`EISDIR: illegal operation on a directory '${source}'`), {
			errno: -21,
			code: 'EISDIR',
			source
		});
	}
};

const fixupAttributes = (destination, stat) => {
	fs.chmodSync(destination, stat.mode);
	fs.chownSync(destination, stat.uid, stat.gid);
};

module.exports.sync = (source, destination, options) => {
	if (!source || !destination) {
		throw new CpFileError('`source` and `destination` required');
	}

	options = {
		overwrite: true,
		...options
	};

	const stat = fs.statSync(source);
	checkSourceIsFile(stat, source);
	fs.makeDirSync(path.dirname(destination));

	const flags = options.overwrite ? null : fsConstants.COPYFILE_EXCL;
	try {
		fs.copyFileSync(source, destination, flags);
	} catch (error) {
		if (!options.overwrite && error.code === 'EEXIST') {
			return;
		}

		throw error;
	}

	fs.utimesSync(destination, stat.atime, stat.mtime);
	fixupAttributes(destination, stat);
};
