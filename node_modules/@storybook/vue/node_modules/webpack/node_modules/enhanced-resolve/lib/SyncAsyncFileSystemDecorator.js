/*
	MIT License http://www.opensource.org/licenses/mit-license.php
	Author Tobias Koppers @sokra
*/

"use strict";

/** @typedef {import("./Resolver").FileSystem} FileSystem */
/** @typedef {import("./Resolver").SyncFileSystem} SyncFileSystem */

/**
 * @param {SyncFileSystem} fs file system implementation
 * @constructor
 */
function SyncAsyncFileSystemDecorator(fs) {
	this.fs = fs;

	this.lstat = undefined;
	this.lstatSync = undefined;
	const lstatSync = fs.lstatSync;
	if (lstatSync) {
		this.lstat = (arg, options, callback) => {
			let result;
			try {
				result = lstatSync.call(fs, arg);
			} catch (e) {
				return (callback || options)(e);
			}
			(callback || options)(null, result);
		};
		this.lstatSync = (arg, options) => lstatSync.call(fs, arg, options);
	}

	this.stat = (arg, options, callback) => {
		let result;
		try {
			result = callback ? fs.statSync(arg, options) : fs.statSync(arg);
		} catch (e) {
			return (callback || options)(e);
		}
		(callback || options)(null, result);
	};
	this.statSync = (arg, options) => fs.statSync(arg, options);

	this.readdir = (arg, options, callback) => {
		let result;
		try {
			result = fs.readdirSync(arg);
		} catch (e) {
			return (callback || options)(e);
		}
		(callback || options)(null, result);
	};
	this.readdirSync = (arg, options) => fs.readdirSync(arg, options);

	this.readFile = (arg, options, callback) => {
		let result;
		try {
			result = fs.readFileSync(arg);
		} catch (e) {
			return (callback || options)(e);
		}
		(callback || options)(null, result);
	};
	this.readFileSync = (arg, options) => fs.readFileSync(arg, options);

	this.readlink = (arg, options, callback) => {
		let result;
		try {
			result = fs.readlinkSync(arg);
		} catch (e) {
			return (callback || options)(e);
		}
		(callback || options)(null, result);
	};
	this.readlinkSync = (arg, options) => fs.readlinkSync(arg, options);

	this.readJson = undefined;
	this.readJsonSync = undefined;
	const readJsonSync = fs.readJsonSync;
	if (readJsonSync) {
		this.readJson = (arg, options, callback) => {
			let result;
			try {
				result = readJsonSync.call(fs, arg);
			} catch (e) {
				return (callback || options)(e);
			}
			(callback || options)(null, result);
		};

		this.readJsonSync = (arg, options) => readJsonSync.call(fs, arg, options);
	}
}
module.exports = SyncAsyncFileSystemDecorator;
