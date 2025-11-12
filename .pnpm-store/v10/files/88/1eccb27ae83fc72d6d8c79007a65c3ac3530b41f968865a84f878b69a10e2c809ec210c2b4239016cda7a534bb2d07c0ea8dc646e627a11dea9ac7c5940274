"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = formatIncompletePhoneNumber;

var _AsYouType = _interopRequireDefault(require("./AsYouType.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

/**
 * Formats a (possibly incomplete) phone number.
 * The phone number can be either in E.164 format
 * or in a form of national number digits.
 * @param {string} value - A possibly incomplete phone number. Either in E.164 format or in a form of national number digits.
 * @param {string|object} [optionsOrDefaultCountry] - A two-letter ("ISO 3166-1 alpha-2") country code, or an object of shape `{ defaultCountry?: string, defaultCallingCode?: string }`.
 * @return {string} Formatted (possibly incomplete) phone number.
 */
function formatIncompletePhoneNumber(value, optionsOrDefaultCountry, metadata) {
  if (!metadata) {
    metadata = optionsOrDefaultCountry;
    optionsOrDefaultCountry = undefined;
  }

  return new _AsYouType["default"](optionsOrDefaultCountry, metadata).input(value);
}
//# sourceMappingURL=formatIncompletePhoneNumber.js.map