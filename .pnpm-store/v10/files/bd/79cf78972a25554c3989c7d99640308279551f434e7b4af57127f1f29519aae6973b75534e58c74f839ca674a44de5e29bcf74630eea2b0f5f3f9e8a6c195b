function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import normalizeArguments from './normalizeArguments.js';
import parsePhoneNumberWithError from './parsePhoneNumberWithError_.js';
import ParseError from './ParseError.js';
import Metadata from './metadata.js';
import checkNumberLength from './helpers/checkNumberLength.js';
export default function validatePhoneNumberLength() {
  var _normalizeArguments = normalizeArguments(arguments),
      text = _normalizeArguments.text,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata;

  options = _objectSpread(_objectSpread({}, options), {}, {
    extract: false
  }); // Parse phone number.

  try {
    var phoneNumber = parsePhoneNumberWithError(text, options, metadata);
    metadata = new Metadata(metadata);
    metadata.selectNumberingPlan(phoneNumber.countryCallingCode);
    var result = checkNumberLength(phoneNumber.nationalNumber, metadata);

    if (result !== 'IS_POSSIBLE') {
      return result;
    }
  } catch (error) {
    /* istanbul ignore else */
    if (error instanceof ParseError) {
      return error.message;
    } else {
      throw error;
    }
  }
}
//# sourceMappingURL=validatePhoneNumberLength.js.map