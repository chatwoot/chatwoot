"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.cache = void 0;

var _fileCache = require("./file-cache");

var _resolvePathInSbCache = require("./resolve-path-in-sb-cache");

var cache = (0, _fileCache.createFileSystemCache)({
  basePath: (0, _resolvePathInSbCache.resolvePathInStorybookCache)('dev-server'),
  ns: 'storybook' // Optional. A grouping namespace for items.

});
exports.cache = cache;