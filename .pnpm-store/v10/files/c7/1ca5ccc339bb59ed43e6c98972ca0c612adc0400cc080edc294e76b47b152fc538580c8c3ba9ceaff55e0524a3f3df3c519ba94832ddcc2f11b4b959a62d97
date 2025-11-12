function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import parsePhoneNumberWithError from './parsePhoneNumberWithError_.js';
import ParseError from './ParseError.js';
import { isSupportedCountry } from './metadata.js';
export default function parsePhoneNumber(text, options, metadata) {
  // Validate `defaultCountry`.
  if (options && options.defaultCountry && !isSupportedCountry(options.defaultCountry, metadata)) {
    options = _objectSpread(_objectSpread({}, options), {}, {
      defaultCountry: undefined
    });
  } // Parse phone number.


  try {
    return parsePhoneNumberWithError(text, options, metadata);
  } catch (error) {
    /* istanbul ignore else */
    if (error instanceof ParseError) {//
    } else {
      throw error;
    }
  }
}
//# sourceMappingURL=parsePhoneNumber_.js.map