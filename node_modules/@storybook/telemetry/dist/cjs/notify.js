"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.notify = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.string.bold.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

var _chalk = _interopRequireDefault(require("chalk"));

var _coreCommon = require("@storybook/core-common");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

var TELEMETRY_KEY_NOTIFY_DATE = 'telemetry-notification-date';
var logger = console;

var notify = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee() {
    var telemetryNotifyDate;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            _context.next = 2;
            return _coreCommon.cache.get(TELEMETRY_KEY_NOTIFY_DATE, null);

          case 2:
            telemetryNotifyDate = _context.sent;

            if (!telemetryNotifyDate) {
              _context.next = 5;
              break;
            }

            return _context.abrupt("return");

          case 5:
            _coreCommon.cache.set(TELEMETRY_KEY_NOTIFY_DATE, Date.now());

            logger.log();
            logger.log("".concat(_chalk.default.magenta.bold('attention'), " => Storybook now collects completely anonymous telemetry regarding usage."));
            logger.log("This information is used to shape Storybook's roadmap and prioritize features.");
            logger.log("You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:");
            logger.log(_chalk.default.cyan('https://storybook.js.org/telemetry'));
            logger.log();

          case 12:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function notify() {
    return _ref.apply(this, arguments);
  };
}();

exports.notify = notify;