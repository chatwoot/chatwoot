"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = getCountryByNationalNumber;

var _metadata = _interopRequireDefault(require("../metadata.js"));

var _getNumberType = _interopRequireDefault(require("./getNumberType.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _createForOfIteratorHelperLoose(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (it) return (it = it.call(o)).next.bind(it); if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; return function () { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function getCountryByNationalNumber(nationalPhoneNumber, _ref) {
  var countries = _ref.countries,
      defaultCountry = _ref.defaultCountry,
      metadata = _ref.metadata;
  // Re-create `metadata` because it will be selecting a `country`.
  metadata = new _metadata["default"](metadata);
  var matchingCountries = [];

  for (var _iterator = _createForOfIteratorHelperLoose(countries), _step; !(_step = _iterator()).done;) {
    var country = _step.value;
    metadata.country(country); // "Leading digits" patterns are only defined for about 20% of all countries.
    // By definition, matching "leading digits" is a sufficient but not a necessary
    // condition for a phone number to belong to a country.
    // The point of "leading digits" check is that it's the fastest one to get a match.
    // https://gitlab.com/catamphetamine/libphonenumber-js/blob/master/METADATA.md#leading_digits
    // I'd suppose that "leading digits" patterns are mutually exclusive for different countries
    // because of the intended use of that feature.

    if (metadata.leadingDigits()) {
      if (nationalPhoneNumber && nationalPhoneNumber.search(metadata.leadingDigits()) === 0) {
        return country;
      }
    } // Else perform full validation with all of those
    // fixed-line/mobile/etc regular expressions.
    else if ((0, _getNumberType["default"])({
      phone: nationalPhoneNumber,
      country: country
    }, undefined, metadata.metadata)) {
      // If the `defaultCountry` is among the `matchingCountries` then return it.
      if (defaultCountry) {
        if (country === defaultCountry) {
          return country;
        }

        matchingCountries.push(country);
      } else {
        return country;
      }
    }
  } // Return the first ("main") one of the `matchingCountries`.


  if (matchingCountries.length > 0) {
    return matchingCountries[0];
  }
}
//# sourceMappingURL=getCountryByNationalNumber.js.map