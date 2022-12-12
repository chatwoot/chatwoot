"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getActualPackageVersions = exports.getActualPackageVersion = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.join.js");

var _path = _interopRequireDefault(require("path"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

var getActualPackageVersions = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(packages) {
    var packageNames;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            packageNames = Object.keys(packages);
            return _context.abrupt("return", Promise.all(packageNames.map(getActualPackageVersion)));

          case 2:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function getActualPackageVersions(_x) {
    return _ref.apply(this, arguments);
  };
}();

exports.getActualPackageVersions = getActualPackageVersions;

var getActualPackageVersion = /*#__PURE__*/function () {
  var _ref2 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(packageName) {
    var packageJson;
    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            _context2.prev = 0;
            // eslint-disable-next-line import/no-dynamic-require,global-require
            packageJson = require(_path.default.join(packageName, 'package.json'));
            return _context2.abrupt("return", {
              name: packageName,
              version: packageJson.version
            });

          case 5:
            _context2.prev = 5;
            _context2.t0 = _context2["catch"](0);
            return _context2.abrupt("return", {
              name: packageName,
              version: null
            });

          case 8:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2, null, [[0, 5]]);
  }));

  return function getActualPackageVersion(_x2) {
    return _ref2.apply(this, arguments);
  };
}();

exports.getActualPackageVersion = getActualPackageVersion;