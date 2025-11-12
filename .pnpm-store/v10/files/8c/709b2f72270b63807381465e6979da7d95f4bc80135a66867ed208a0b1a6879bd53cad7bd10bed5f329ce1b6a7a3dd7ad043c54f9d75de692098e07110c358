"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = findPhoneNumbers;
exports.searchPhoneNumbers = searchPhoneNumbers;

var _findPhoneNumbersInitialImplementation = _interopRequireWildcard(require("./findPhoneNumbersInitialImplementation.js"));

var _normalizeArguments3 = _interopRequireDefault(require("../normalizeArguments.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

// This is a legacy function.
// Use `findNumbers()` instead.
function findPhoneNumbers() {
  var _normalizeArguments = (0, _normalizeArguments3["default"])(arguments),
      text = _normalizeArguments.text,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata;

  return (0, _findPhoneNumbersInitialImplementation["default"])(text, options, metadata);
}
/**
 * @return ES6 `for ... of` iterator.
 */


function searchPhoneNumbers() {
  var _normalizeArguments2 = (0, _normalizeArguments3["default"])(arguments),
      text = _normalizeArguments2.text,
      options = _normalizeArguments2.options,
      metadata = _normalizeArguments2.metadata;

  return (0, _findPhoneNumbersInitialImplementation.searchPhoneNumbers)(text, options, metadata);
}
//# sourceMappingURL=findPhoneNumbers.js.map