'use strict';
const {promisify} = require('util');
const fs = require('graceful-fs');
const makeDir = require('make-dir');
const pEvent = require('p-event');
const CpFileError = require('./cp-file-error');

const stat = promisify(fs.stat);
const lstat = promisify(fs.lstat);
const utimes = promisify(fs.utimes);
const chmod = promisify(fs.chmod);
const chown = promisify(fs.chown);

exports.closeSync = fs.closeSync.bind(fs);
exports.createWriteStream = fs.createWriteStream.bind(fs);

exports.createReadStream = async (path, options) => {
	const read = fs.createReadStream(path, options);

	try {
		await pEvent(read, ['readable', 'end']);
	} catch (error) {
		throw new CpFileError(`Cannot read from \`${path}\`: ${error.message}`, error);
	}

	return read;
};

exports.stat = path => stat(path).catch(error => {
	throw new CpFileError(`Cannot stat path \`${path}\`: ${error.message}`, error);
});

exports.lstat = path => lstat(path).catch(error => {
	throw new CpFileError(`lstat \`${path}\` failed: ${error.message}`, error);
});

exports.utimes = (path, atime, mtime) => utimes(path, atime, mtime).catch(error => {
	throw new CpFileError(`utimes \`${path}\` failed: ${error.message}`, error);
});

exports.chmod = (path, mode) => chmod(path, mode).catch(error => {
	throw new CpFileError(`chmod \`${path}\` failed: ${error.message}`, error);
});

exports.chown = (path, uid, gid) => chown(path, uid, gid).catch(error => {
	throw new CpFileError(`chown \`${path}\` failed: ${error.message}`, error);
});

exports.statSync = path => {
	try {
		return fs.statSync(path);
	} catch (error) {
		throw new CpFileError(`stat \`${path}\` failed: ${error.message}`, error);
	}
};

exports.utimesSync = (path, atime, mtime) => {
	try {
		return fs.utimesSync(path, atime, mtime);
	} catch (error) {
		throw new CpFileError(`utimes \`${path}\` failed: ${error.message}`, error);
	}
};

exports.chmodSync = (path, mode) => {
	try {
		return fs.chmodSync(path, mode);
	} catch (error) {
		throw new CpFileError(`chmod \`${path}\` failed: ${error.message}`, error);
	}
};

exports.chownSync = (path, uid, gid) => {
	try {
		return fs.chownSync(path, uid, gid);
	} catch (error) {
		throw new CpFileError(`chown \`${path}\` failed: ${error.message}`, error);
	}
};

exports.makeDir = path => makeDir(path, {fs}).catch(error => {
	throw new CpFileError(`Cannot create directory \`${path}\`: ${error.message}`, error);
});

exports.makeDirSync = path => {
	try {
		makeDir.sync(path, {fs});
	} catch (error) {
		throw new CpFileError(`Cannot create directory \`${path}\`: ${error.message}`, error);
	}
};

exports.copyFileSync = (source, destination, flags) => {
	try {
		fs.copyFileSync(source, destination, flags);
	} catch (error) {
		throw new CpFileError(`Cannot copy from \`${source}\` to \`${destination}\`: ${error.message}`, error);
	}
};
