"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = searchNumbers;

var _normalizeArguments2 = _interopRequireDefault(require("../normalizeArguments.js"));

var _PhoneNumberMatcher = _interopRequireDefault(require("../PhoneNumberMatcher.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

/**
 * @return ES6 `for ... of` iterator.
 */
function searchNumbers() {
  var _normalizeArguments = (0, _normalizeArguments2["default"])(arguments),
      text = _normalizeArguments.text,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata;

  var matcher = new _PhoneNumberMatcher["default"](text, options, metadata);
  return _defineProperty({}, Symbol.iterator, function () {
    return {
      next: function next() {
        if (matcher.hasNext()) {
          return {
            done: false,
            value: matcher.next()
          };
        }

        return {
          done: true
        };
      }
    };
  });
}
//# sourceMappingURL=searchNumbers.js.map