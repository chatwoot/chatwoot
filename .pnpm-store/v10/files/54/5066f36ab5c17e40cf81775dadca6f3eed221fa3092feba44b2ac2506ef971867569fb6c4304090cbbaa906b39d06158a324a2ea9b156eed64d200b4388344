"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = nextFriday;

var _index = _interopRequireDefault(require("../_lib/requiredArgs/index.js"));

var _index2 = _interopRequireDefault(require("../nextDay/index.js"));

var _index3 = _interopRequireDefault(require("../toDate/index.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * @name nextFriday
 * @category Weekday Helpers
 * @summary When is the next Friday?
 *
 * @description
 * When is the next Friday?
 *
 * @param {Date | number} date - the date to start counting from
 * @returns {Date} the next Friday
 * @throws {TypeError} 1 argument required
 *
 * @example
 * // When is the next Friday after Mar, 22, 2020?
 * const result = nextFriday(new Date(2020, 2, 22))
 * //=> Fri Mar 27 2020 00:00:00
 */
function nextFriday(date) {
  (0, _index.default)(1, arguments);
  return (0, _index2.default)((0, _index3.default)(date), 5);
}

module.exports = exports.default;