"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.FileSystemCache = void 0;
exports.createFileSystemCache = createFileSystemCache;

var _fileSystemCache = _interopRequireDefault(require("file-system-cache"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// @ts-ignore - this package has no typings, so we wrap it and add typings that way, because we expose it
class FileSystemCache {
  constructor(options) {
    this.internal = void 0;
    this.internal = (0, _fileSystemCache.default)(options);
  }

  path(key) {
    return this.internal.path(key);
  }

  fileExists(key) {
    return this.internal.fileExists(key);
  }

  ensureBasePath() {
    return this.internal.ensureBasePath();
  }

  get(key, defaultValue) {
    return this.internal.get(key, defaultValue);
  }

  getSync(key, defaultValue) {
    return this.internal.getSync(key, defaultValue);
  }

  set(key, value) {
    return this.internal.set(key, value);
  }

  setSync(key, value) {
    this.internal.setSync(key, value);
    return this;
  }

  remove(key) {
    return this.internal.remove(key);
  }

  clear() {
    return this.internal.clear();
  }

  save() {
    return this.internal.save();
  }

  load() {
    return this.internal.load();
  }

}

exports.FileSystemCache = FileSystemCache;

function createFileSystemCache(options) {
  return new FileSystemCache(options);
}