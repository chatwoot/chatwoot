"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.outputStats = outputStats;
exports.writeStats = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

var _chalk = _interopRequireDefault(require("chalk"));

var _path = _interopRequireDefault(require("path"));

var _nodeLogger = require("@storybook/node-logger");

var _fsExtra = _interopRequireDefault(require("fs-extra"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function outputStats(_x, _x2, _x3) {
  return _outputStats.apply(this, arguments);
}

function _outputStats() {
  _outputStats = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(directory, previewStats, managerStats) {
    var filePath, _filePath;

    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            if (!previewStats) {
              _context2.next = 5;
              break;
            }

            _context2.next = 3;
            return writeStats(directory, 'preview', previewStats);

          case 3:
            filePath = _context2.sent;

            _nodeLogger.logger.info("=> preview stats written to ".concat(_chalk.default.cyan(filePath)));

          case 5:
            if (!managerStats) {
              _context2.next = 10;
              break;
            }

            _context2.next = 8;
            return writeStats(directory, 'manager', managerStats);

          case 8:
            _filePath = _context2.sent;

            _nodeLogger.logger.info("=> manager stats written to ".concat(_chalk.default.cyan(_filePath)));

          case 10:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2);
  }));
  return _outputStats.apply(this, arguments);
}

var writeStats = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(directory, name, stats) {
    var filePath;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            filePath = _path.default.join(directory, "".concat(name, "-stats.json"));
            _context.next = 3;
            return _fsExtra.default.outputFile(filePath, JSON.stringify(stats.toJson(), null, 2), 'utf8');

          case 3:
            return _context.abrupt("return", filePath);

          case 4:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function writeStats(_x4, _x5, _x6) {
    return _ref.apply(this, arguments);
  };
}();

exports.writeStats = writeStats;