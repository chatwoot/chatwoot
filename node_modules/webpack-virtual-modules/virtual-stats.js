/**
 * Used to cache a stats object for the virtual file.
 * Extracted from the `mock-fs` package.
 *
 * @author Tim Schaub http://tschaub.net/
 * @link https://github.com/tschaub/mock-fs/blob/master/lib/binding.js
 * @link https://github.com/tschaub/mock-fs/blob/master/license.md
 */

/* eslint-disable no-restricted-syntax, no-prototype-builtins, no-continue */
/* eslint-disable no-bitwise, no-underscore-dangle */

'use strict';

var constants = require('constants');

/**
 * Create a new stats object.
 * @param {Object} config Stats properties.
 * @constructor
 */
function VirtualStats(config) {
  for (var key in config) {
    if (!config.hasOwnProperty(key)) {
      continue;
    }
    this[key] = config[key];
  }
}

/**
 * Check if mode indicates property.
 * @param {number} property Property to check.
 * @return {boolean} Property matches mode.
 */
VirtualStats.prototype._checkModeProperty = function(property) {
  return ((this.mode & constants.S_IFMT) === property);
};


/**
 * @return {Boolean} Is a directory.
 */
VirtualStats.prototype.isDirectory = function() {
  return this._checkModeProperty(constants.S_IFDIR);
};


/**
 * @return {Boolean} Is a regular file.
 */
VirtualStats.prototype.isFile = function() {
  return this._checkModeProperty(constants.S_IFREG);
};


/**
 * @return {Boolean} Is a block device.
 */
VirtualStats.prototype.isBlockDevice = function() {
  return this._checkModeProperty(constants.S_IFBLK);
};


/**
 * @return {Boolean} Is a character device.
 */
VirtualStats.prototype.isCharacterDevice = function() {
  return this._checkModeProperty(constants.S_IFCHR);
};


/**
 * @return {Boolean} Is a symbolic link.
 */
VirtualStats.prototype.isSymbolicLink = function() {
  return this._checkModeProperty(constants.S_IFLNK);
};


/**
 * @return {Boolean} Is a named pipe.
 */
VirtualStats.prototype.isFIFO = function() {
  return this._checkModeProperty(constants.S_IFIFO);
};


/**
 * @return {Boolean} Is a socket.
 */
VirtualStats.prototype.isSocket = function() {
  return this._checkModeProperty(constants.S_IFSOCK);
};

module.exports = VirtualStats;
