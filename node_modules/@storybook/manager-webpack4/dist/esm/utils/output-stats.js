import "regenerator-runtime/runtime.js";
import "core-js/modules/es.array.join.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import chalk from 'chalk';
import path from 'path';
import { logger } from '@storybook/node-logger';
import fs from 'fs-extra';
export function outputStats(_x, _x2, _x3) {
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
            logger.info("=> preview stats written to ".concat(chalk.cyan(filePath)));

          case 5:
            if (!managerStats) {
              _context2.next = 10;
              break;
            }

            _context2.next = 8;
            return writeStats(directory, 'manager', managerStats);

          case 8:
            _filePath = _context2.sent;
            logger.info("=> manager stats written to ".concat(chalk.cyan(_filePath)));

          case 10:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2);
  }));
  return _outputStats.apply(this, arguments);
}

export var writeStats = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(directory, name, stats) {
    var filePath;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            filePath = path.join(directory, "".concat(name, "-stats.json"));
            _context.next = 3;
            return fs.outputFile(filePath, JSON.stringify(stats.toJson(), null, 2), 'utf8');

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