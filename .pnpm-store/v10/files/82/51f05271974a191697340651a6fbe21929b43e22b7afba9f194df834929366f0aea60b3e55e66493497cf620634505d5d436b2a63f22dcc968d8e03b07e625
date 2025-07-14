"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = extractFormattedPhoneNumberFromPossibleRfc3966NumberUri;

var _extractPhoneContext = _interopRequireWildcard(require("./extractPhoneContext.js"));

var _ParseError = _interopRequireDefault(require("../ParseError.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

/**
 * @param  {string} numberToParse
 * @param  {string} nationalNumber
 * @return {}
 */
function extractFormattedPhoneNumberFromPossibleRfc3966NumberUri(numberToParse, _ref) {
  var extractFormattedPhoneNumber = _ref.extractFormattedPhoneNumber;
  var phoneContext = (0, _extractPhoneContext["default"])(numberToParse);

  if (!(0, _extractPhoneContext.isPhoneContextValid)(phoneContext)) {
    throw new _ParseError["default"]('NOT_A_NUMBER');
  }

  var phoneNumberString;

  if (phoneContext === null) {
    // Extract a possible number from the string passed in.
    // (this strips leading characters that could not be the start of a phone number)
    phoneNumberString = extractFormattedPhoneNumber(numberToParse) || '';
  } else {
    phoneNumberString = ''; // If the phone context contains a phone number prefix, we need to capture
    // it, whereas domains will be ignored.

    if (phoneContext.charAt(0) === _extractPhoneContext.PLUS_SIGN) {
      phoneNumberString += phoneContext;
    } // Now append everything between the "tel:" prefix and the phone-context.
    // This should include the national number, an optional extension or
    // isdn-subaddress component. Note we also handle the case when "tel:" is
    // missing, as we have seen in some of the phone number inputs.
    // In that case, we append everything from the beginning.


    var indexOfRfc3966Prefix = numberToParse.indexOf(_extractPhoneContext.RFC3966_PREFIX_);
    var indexOfNationalNumber; // RFC 3966 "tel:" prefix is preset at this stage because
    // `isPhoneContextValid()` requires it to be present.

    /* istanbul ignore else */

    if (indexOfRfc3966Prefix >= 0) {
      indexOfNationalNumber = indexOfRfc3966Prefix + _extractPhoneContext.RFC3966_PREFIX_.length;
    } else {
      indexOfNationalNumber = 0;
    }

    var indexOfPhoneContext = numberToParse.indexOf(_extractPhoneContext.RFC3966_PHONE_CONTEXT_);
    phoneNumberString += numberToParse.substring(indexOfNationalNumber, indexOfPhoneContext);
  } // Delete the isdn-subaddress and everything after it if it is present.
  // Note extension won't appear at the same time with isdn-subaddress
  // according to paragraph 5.3 of the RFC3966 spec.


  var indexOfIsdn = phoneNumberString.indexOf(_extractPhoneContext.RFC3966_ISDN_SUBADDRESS_);

  if (indexOfIsdn > 0) {
    phoneNumberString = phoneNumberString.substring(0, indexOfIsdn);
  } // If both phone context and isdn-subaddress are absent but other
  // parameters are present, the parameters are left in nationalNumber.
  // This is because we are concerned about deleting content from a potential
  // number string when there is no strong evidence that the number is
  // actually written in RFC3966.


  if (phoneNumberString !== '') {
    return phoneNumberString;
  }
}
//# sourceMappingURL=extractFormattedPhoneNumberFromPossibleRfc3966NumberUri.js.map