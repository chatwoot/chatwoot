"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = findNumbers;

var _PhoneNumberMatcher = _interopRequireDefault(require("../PhoneNumberMatcher.js"));

var _normalizeArguments2 = _interopRequireDefault(require("../normalizeArguments.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function findNumbers() {
  var _normalizeArguments = (0, _normalizeArguments2["default"])(arguments),
      text = _normalizeArguments.text,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata;

  var matcher = new _PhoneNumberMatcher["default"](text, options, metadata);
  var results = [];

  while (matcher.hasNext()) {
    results.push(matcher.next());
  }

  return results;
}
//# sourceMappingURL=findNumbers.js.map