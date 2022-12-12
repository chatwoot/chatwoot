'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
    return data;
  };

  return data;
}

var _constants = _interopRequireDefault(require('./constants'));

var fastPath = _interopRequireWildcard(require('./lib/fast_path'));

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }
  return obj;
}

class HasteFS {
  constructor({rootDir, files}) {
    _defineProperty(this, '_rootDir', void 0);

    _defineProperty(this, '_files', void 0);

    this._rootDir = rootDir;
    this._files = files;
  }

  getModuleName(file) {
    const fileMetadata = this._getFileData(file);

    return (fileMetadata && fileMetadata[_constants.default.ID]) || null;
  }

  getSize(file) {
    const fileMetadata = this._getFileData(file);

    return (fileMetadata && fileMetadata[_constants.default.SIZE]) || null;
  }

  getDependencies(file) {
    const fileMetadata = this._getFileData(file);

    if (fileMetadata) {
      return fileMetadata[_constants.default.DEPENDENCIES]
        ? fileMetadata[_constants.default.DEPENDENCIES].split(
            _constants.default.DEPENDENCY_DELIM
          )
        : [];
    } else {
      return null;
    }
  }

  getSha1(file) {
    const fileMetadata = this._getFileData(file);

    return (fileMetadata && fileMetadata[_constants.default.SHA1]) || null;
  }

  exists(file) {
    return this._getFileData(file) != null;
  }

  getAllFiles() {
    return Array.from(this.getAbsoluteFileIterator());
  }

  getFileIterator() {
    return this._files.keys();
  }

  *getAbsoluteFileIterator() {
    for (const file of this.getFileIterator()) {
      yield fastPath.resolve(this._rootDir, file);
    }
  }

  matchFiles(pattern) {
    if (!(pattern instanceof RegExp)) {
      pattern = new RegExp(pattern);
    }

    const files = [];

    for (const file of this.getAbsoluteFileIterator()) {
      if (pattern.test(file)) {
        files.push(file);
      }
    }

    return files;
  }

  matchFilesWithGlob(globs, root) {
    const files = new Set();
    const matcher = (0, _jestUtil().globsToMatcher)(globs);

    for (const file of this.getAbsoluteFileIterator()) {
      const filePath = root ? fastPath.relative(root, file) : file;

      if (matcher((0, _jestUtil().replacePathSepForGlob)(filePath))) {
        files.add(file);
      }
    }

    return files;
  }

  _getFileData(file) {
    const relativePath = fastPath.relative(this._rootDir, file);
    return this._files.get(relativePath);
  }
}

exports.default = HasteFS;
