'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _ramda = require('ramda');

var _ramda2 = _interopRequireDefault(_ramda);

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

var _fsExtra = require('fs-extra');

var _fsExtra2 = _interopRequireDefault(_fsExtra);

var _funcs = require('./funcs');

var f = _interopRequireWildcard(_funcs);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var formatPath = _ramda2.default.pipe(f.ensureString('./.cache'), f.toAbsolutePath);

var toGetValue = function toGetValue(data) {
  var type = data.type;
  var value = data.value;

  if (type === 'Date') {
    value = new Date(value);
  }
  return value;
};

var getValueP = function getValueP(path, defaultValue) {
  return new _bluebird2.default(function (resolve, reject) {
    _fsExtra2.default.readJson(path, function (err, result) {
      if (err) {
        if (err.code === 'ENOENT') {
          resolve(defaultValue);
        } else {
          reject(err);
        }
      } else {
        var value = toGetValue(result);
        resolve(value);
      }
    });
  });
};

var toJson = function toJson(value) {
  return JSON.stringify({ value: value, type: _ramda2.default.type(value) });
};

/**
 * A cache that read/writes to a specific part of the file-system.
 */

var FileSystemCache = function () {
  /**
   * Constructor.
   * @param options
   *            - basePath:   The folder path to read/write to.
   *                          Default: './build'
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
      throw new Error('The basePath \'' + this.basePath + '\' is a file. It should be a folder.');
    }
  }

  /**
   * Generates the path to the cached files.
   * @param {string} key: The key of the cache item.
   * @return {string}.
   */


  _createClass(FileSystemCache, [{
    key: 'path',
    value: function path(key) {
      if (f.isNothing(key)) {
        throw new Error('Path requires a cache key.');
      }
      var name = f.hash(key);
      if (this.ns) {
        name = this.ns + '-' + name;
      }
      if (this.extension) {
        name = name + '.' + this.extension.replace(/^\./, '');
      }
      return this.basePath + '/' + name;
    }

    /**
     * Determines whether the file exists.
     * @param {string} key: The key of the cache item.
     * @return {Promise}
     */

  }, {
    key: 'fileExists',
    value: function fileExists(key) {
      return f.existsP(this.path(key));
    }

    /**
     * Ensure that the base path exists.
     * @return {Promise}
     */

  }, {
    key: 'ensureBasePath',
    value: function ensureBasePath() {
      var _this = this;

      return new _bluebird2.default(function (resolve, reject) {
        if (_this.basePathExists) {
          resolve();
        } else {
          _fsExtra2.default.ensureDir(_this.basePath, function (err) {
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
     * @param defaultValue: Optional. A default value to return if the value does not exist in cache.
     * @return {Promise} - File contents, or
     *                     undefined if the file does not exist.
     */

  }, {
    key: 'get',
    value: function get(key, defaultValue) {
      return getValueP(this.path(key), defaultValue);
    }

    /**
     * Gets the contents of the file with the given key.
     * @param {string} key: The key of the cache item.
     * @param defaultValue: Optional. A default value to return if the value does not exist in cache.
     * @return the cached value, or undefined.
     */

  }, {
    key: 'getSync',
    value: function getSync(key, defaultValue) {
      var path = this.path(key);
      return _fsExtra2.default.existsSync(path) ? toGetValue(_fsExtra2.default.readJsonSync(path)) : defaultValue;
    }

    /**
     * Writes the given value to the file-system.
     * @param {string} key: The key of the cache item.
     * @param value: The value to write (Primitive or Object).
     * @return {Promise}
     */

  }, {
    key: 'set',
    value: function set(key, value) {
      var _this2 = this;

      var path = this.path(key);
      return new _bluebird2.default(function (resolve, reject) {
        _this2.ensureBasePath().then(function () {
          _fsExtra2.default.outputFile(path, toJson(value), function (err) {
            if (err) {
              reject(err);
            } else {
              resolve({ path: path });
            }
          });
        }).catch(function (err) {
          return reject(err);
        });
      });
    }

    /**
     * Writes the given value to the file-system and memory cache.
     * @param {string} key: The key of the cache item.
     * @param value: The value to write (Primitive or Object).
     * @return the cache.
     */

  }, {
    key: 'setSync',
    value: function setSync(key, value) {
      _fsExtra2.default.outputFileSync(this.path(key), toJson(value));
      return this;
    }

    /**
     * Removes the item from the file-system.
     * @param {string} key: The key of the cache item.
     * @return {Promise}
     */

  }, {
    key: 'remove',
    value: function remove(key) {
      return f.removeFileP(this.path(key));
    }

    /**
     * Removes all items from the cache.
     * @return {Promise}
     */

  }, {
    key: 'clear',
    value: function clear() {
      var _this3 = this;

      return new _bluebird2.default(function (resolve, reject) {
        f.filePathsP(_this3.basePath, _this3.ns).then(function (paths) {
          var remove = function remove(index) {
            var path = paths[index];
            if (path) {
              f.removeFileP(path).then(function () {
                return remove(index + 1);
              }) // <== RECURSION.
              .catch(function (err) {
                return reject(err);
              });
            } else {
              resolve(); // All files have been removed.
            }
          };
          remove(0);
        }).catch(function (err) {
          return reject(err);
        });
      });
    }

    /**
     * Saves several items to the cache in one operation.
     * @param {array} items: An array of objects of the form { key, value }.
     * @return {Promise}
     */

  }, {
    key: 'save',
    value: function save(items) {
      var _this4 = this;

      // Setup initial conditions.
      if (!_ramda2.default.is(Array, items)) {
        items = [items];
      }
      var isValid = function isValid(item) {
        if (!_ramda2.default.is(Object, item)) {
          return false;
        }
        return item.key && item.value;
      };
      items = _ramda2.default.pipe(_ramda2.default.reject(_ramda2.default.isNil), _ramda2.default.forEach(function (item) {
        if (!isValid(item)) {
          throw new Error('Save items not valid, must be an array of {key, value} objects.');
        }
      }))(items);

      return new _bluebird2.default(function (resolve, reject) {
        // Don't continue if no items were passed.
        var response = { paths: [] };
        if (items.length === 0) {
          resolve(response);
          return;
        }

        // Recursively set each item to the file-system.
        var setValue = function setValue(index) {
          var item = items[index];
          if (item) {
            _this4.set(item.key, item.value).then(function (result) {
              response.paths[index] = result.path;
              setValue(index + 1); // <== RECURSION.
            }).catch(function (err) {
              return reject(err);
            });
          } else {
            // No more items - done.
            resolve(response);
          }
        };
        setValue(0);
      });
    }

    /**
     * Loads all files within the cache's namespace.
     */

  }, {
    key: 'load',
    value: function load() {
      var _this5 = this;

      return new _bluebird2.default(function (resolve, reject) {
        f.filePathsP(_this5.basePath, _this5.ns).then(function (paths) {
          // Bail out if there are no paths in the folder.
          var response = { files: [] };
          if (paths.length === 0) {
            resolve(response);
            return;
          }

          // Get each value.
          var getValue = function getValue(index) {
            var path = paths[index];
            if (path) {
              getValueP(path).then(function (result) {
                response.files[index] = { path: path, value: result };
                getValue(index + 1); // <== RECURSION.
              }).catch(function (err) {
                return reject(err);
              });
            } else {
              // All paths have been loaded.
              resolve(response);
            }
          };
          getValue(0);
        }).catch(function (err) {
          return reject(err);
        });
      });
    }
  }]);

  return FileSystemCache;
}();

exports.default = FileSystemCache;
//# sourceMappingURL=cache.js.map