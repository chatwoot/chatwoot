'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.hash = exports.filePathsP = exports.removeFileP = exports.existsP = exports.readFileSync = exports.isFileSync = exports.ensureString = exports.toAbsolutePath = exports.toStringArray = exports.compact = exports.isString = exports.isNothing = undefined;

var _ramda = require('ramda');

var _ramda2 = _interopRequireDefault(_ramda);

var _fsExtra = require('fs-extra');

var _fsExtra2 = _interopRequireDefault(_fsExtra);

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _crypto = require('crypto');

var _crypto2 = _interopRequireDefault(_crypto);

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var isNothing = exports.isNothing = function isNothing(value) {
  return _ramda2.default.isNil(value) || _ramda2.default.isEmpty(value);
};
var isString = exports.isString = _ramda2.default.is(String);
var compact = exports.compact = _ramda2.default.pipe(_ramda2.default.flatten, _ramda2.default.reject(_ramda2.default.isNil));
var toStringArray = exports.toStringArray = _ramda2.default.pipe(compact, _ramda2.default.map(_ramda2.default.toString));
var toAbsolutePath = exports.toAbsolutePath = function toAbsolutePath(path) {
  return path.startsWith('.') ? _path2.default.resolve(path) : path;
};
var ensureString = exports.ensureString = _ramda2.default.curry(function (defaultValue, text) {
  return _ramda2.default.is(String, text) ? text : defaultValue;
});

var isFileSync = exports.isFileSync = function isFileSync(path) {
  if (_fsExtra2.default.existsSync(path)) {
    return _fsExtra2.default.lstatSync(path).isFile();
  }
  return false;
};

var readFileSync = exports.readFileSync = function readFileSync(path) {
  if (_fsExtra2.default.existsSync(path)) {
    return _fsExtra2.default.readFileSync(path).toString();
  }
};

var existsP = exports.existsP = function existsP(path) {
  return new _bluebird2.default(function (resolve) {
    _fsExtra2.default.exists(path, function (exists) {
      return resolve(exists);
    });
  });
};

var removeFileP = exports.removeFileP = function removeFileP(path) {
  return new _bluebird2.default(function (resolve, reject) {
    existsP(path).then(function (exists) {
      if (exists) {
        _fsExtra2.default.remove(path, function (err) {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      } else {
        resolve();
      }
    });
  });
};

var filePathsP = exports.filePathsP = function filePathsP(basePath, ns) {
  return new _bluebird2.default(function (resolve, reject) {
    existsP(basePath).then(function (exists) {
      if (!exists) {
        resolve([]);return;
      }
      _fsExtra2.default.readdir(basePath, function (err, fileNames) {
        if (err) {
          reject(err);
        } else {
          var paths = _ramda2.default.pipe(compact, _ramda2.default.filter(function (name) {
            return ns ? name.startsWith(ns) : true;
          }), _ramda2.default.filter(function (name) {
            return !ns ? !_ramda2.default.contains('-')(name) : true;
          }), _ramda2.default.map(function (name) {
            return basePath + '/' + name;
          }))(fileNames);
          resolve(paths);
        }
      });
    });
  });
};

/**
 * Turns a set of values into a HEX hash code.
 * @param values: The set of values to hash.
 * @return {String} or undefined.
 */
var hash = exports.hash = function hash() {
  for (var _len = arguments.length, values = Array(_len), _key = 0; _key < _len; _key++) {
    values[_key] = arguments[_key];
  }

  if (_ramda2.default.pipe(compact, _ramda2.default.isEmpty)(values)) {
    return undefined;
  }
  var resultHash = _crypto2.default.createHash('md5');
  var addValue = function addValue(value) {
    return resultHash.update(value);
  };
  var addValues = _ramda2.default.forEach(addValue);
  _ramda2.default.pipe(toStringArray, addValues)(values);
  return resultHash.digest('hex');
};
//# sourceMappingURL=funcs.js.map