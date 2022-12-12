"use strict";
Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj["default"] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var _ramda = require("ramda");

var _ramda2 = _interopRequireDefault(_ramda);

var _bluebird = require("bluebird");

var _bluebird2 = _interopRequireDefault(_bluebird);

var _fsExtra = require("fs-extra");

var _fsExtra2 = _interopRequireDefault(_fsExtra);

var _funcs = require("./funcs");

var f = _interopRequireWildcard(_funcs);

var formatPath = _ramda2["default"].pipe(f.ensureString("./.build"), f.toAbsolutePath);

/**
 * A cache that read/writes to a specific part of the file-system.
 */

var FileSystemCache = (function () {
  /**
   * Constructor.
   * @param options
   *            - basePath:   The folder path to read/write to.
   *                          Default: "./build"
   *            - ns:         A single value, or array, that represents a
   *                          a unique namespace within which values for this
   *                          store are cached.
   *            - extension:  An optional file-extension for paths.
   */

  function FileSystemCache() {
    var _ref = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

    var basePath = _ref.basePath;
    var ns = _ref.ns;
    var extension = _ref.extension;

    _classCallCheck(this, FileSystemCache);

    this.basePath = formatPath(basePath);
    this.ns = f.hash(ns);
    if (f.isString(extension)) {
      this.extension = extension;
    }
    if (f.isFileSync(this.basePath)) {
      throw new Error("The basePath '" + this.basePath + "' is a file. It should be a folder.");
    }
  }

  /**
   * Generates the path to the cached files.
   * @param {string} key: The key of the cache item.
   * @return {string}.
   */

  _createClass(FileSystemCache, [{
    key: "path",
    value: function path(key) {
      if (f.isNothing(key)) {
        throw new Error("Path requires a cache key.");
      }
      var name = f.hash(key);
      if (this.ns) {
        name = this.ns + "-" + name;
      }
      if (this.extension) {
        name = name + "." + this.extension.replace(/^\./, "");
      }
      return this.basePath + "/" + name;
    }

    /**
     * Determines whether the file exists.
     * @param {string} key: The key of the cache item.
     * @return {Promise}
     */
  }, {
    key: "fileExists",
    value: function fileExists(key) {
      return f.fileExistsP(this.path(key));
    }

    /**
     * Ensure that the base path exists.
     * @return {Promise}
     */
  }, {
    key: "ensureBasePath",
    value: function ensureBasePath() {
      var _this = this;

      return new _bluebird2["default"](function (resolve, reject) {
        if (_this.basePathExists) {
          resolve();
        } else {
          _fsExtra2["default"].ensureDir(_this.basePath, function (err) {
            if (err) {
              reject(err);
            } else {
              _this.basePathExists = true;
              resolve();
            }
          });
        }
      });
    }

    /**
     * Gets the contents of the file with the given key.
     * @param {string} key: The key of the cache item.
     * @return {Promise} - File contents, or
     *                     Undefined if the file does not exist.
     */
  }, {
    key: "get",
    value: function get(key) {
      var _this2 = this;

      return new _bluebird2["default"](function (resolve, reject) {
        var path = _this2.path(key);
        _fsExtra2["default"].readJson(path, function (err, result) {
          if (err) {
            if (err.code === "ENOENT") {
              resolve(undefined);
            } else {
              reject(err);
            }
          } else {
            var value = result.value;
            var type = result.type;

            if (type === "Date") {
              value = new Date(value);
            }
            resolve(value);
          }
        });
      });
    }

    /**
     * Writes the given value to the file-system and memory cache.
     * @param {string} key: The key of the cache item.
     * @param value: The value to write (Primitive or Object).
     * @return {Promise}
     */
  }, {
    key: "set",
    value: function set(key, value) {
      var _this3 = this;

      var path = this.path(key);
      return new _bluebird2["default"](function (resolve, reject) {
        _this3.ensureBasePath().then(function () {
          var json = {
            value: value,
            type: _ramda2["default"].type(value)
          };
          _fsExtra2["default"].outputFile(path, JSON.stringify(json), function (err) {
            if (err) {
              reject(err);
            } else {
              resolve({ path: path });
            }
          });
        })["catch"](function (err) {
          return reject(err);
        });
      });
    }

    /**
     * Removes the item from the file-system.
     * @param {string} key: The key of the cache item.
     * @return {Promise}
     */
  }, {
    key: "remove",
    value: function remove(key) {
      return f.removeFileP(this.path(key));
    }

    /**
     * Removes all items from the cache.
     * @return {Promise}
     */
  }, {
    key: "clear",
    value: function clear() {
      var _this4 = this;

      return new _bluebird2["default"](function (resolve, reject) {
        _fsExtra2["default"].readdir(_this4.basePath, function (err, fileNames) {
          if (err) {
            reject(err);
          } else {
            (function () {
              var paths = _ramda2["default"].pipe(f.compact, _ramda2["default"].filter(function (name) {
                return _this4.ns ? name.startsWith(_this4.ns) : true;
              }), _ramda2["default"].filter(function (name) {
                return !_this4.ns ? !_ramda2["default"].contains("-")(name) : true;
              }), _ramda2["default"].map(function (name) {
                return _this4.basePath + "/" + name;
              }))(fileNames);

              var remove = function remove(index) {
                var path = paths[index];
                if (path) {
                  f.removeFileP(path).then(function () {
                    return remove(index + 1);
                  }) // <== RECURSION
                  ["catch"](function (err) {
                    return reject(err);
                  });
                } else {
                  resolve(); // All files have been removed.
                }
              };
              remove(0);
            })();
          }
        });
      });
    }
  }]);

  return FileSystemCache;
})();

exports["default"] = FileSystemCache;
module.exports = exports["default"];