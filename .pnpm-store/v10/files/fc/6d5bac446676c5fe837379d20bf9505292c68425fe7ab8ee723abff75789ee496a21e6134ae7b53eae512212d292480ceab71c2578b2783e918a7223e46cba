"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.FIRST_GROUP_PATTERN = void 0;
exports["default"] = formatNationalNumberUsingFormat;

var _applyInternationalSeparatorStyle = _interopRequireDefault(require("./applyInternationalSeparatorStyle.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

// This was originally set to $1 but there are some countries for which the
// first group is not used in the national pattern (e.g. Argentina) so the $1
// group does not match correctly. Therefore, we use `\d`, so that the first
// group actually used in the pattern will be matched.
var FIRST_GROUP_PATTERN = /(\$\d)/;
exports.FIRST_GROUP_PATTERN = FIRST_GROUP_PATTERN;

function formatNationalNumberUsingFormat(number, format, _ref) {
  var useInternationalFormat = _ref.useInternationalFormat,
      withNationalPrefix = _ref.withNationalPrefix,
      carrierCode = _ref.carrierCode,
      metadata = _ref.metadata;
  var formattedNumber = number.replace(new RegExp(format.pattern()), useInternationalFormat ? format.internationalFormat() : // This library doesn't use `domestic_carrier_code_formatting_rule`,
  // because that one is only used when formatting phone numbers
  // for dialing from a mobile phone, and this is not a dialing library.
  // carrierCode && format.domesticCarrierCodeFormattingRule()
  // 	// First, replace the $CC in the formatting rule with the desired carrier code.
  // 	// Then, replace the $FG in the formatting rule with the first group
  // 	// and the carrier code combined in the appropriate way.
  // 	? format.format().replace(FIRST_GROUP_PATTERN, format.domesticCarrierCodeFormattingRule().replace('$CC', carrierCode))
  // 	: (
  // 		withNationalPrefix && format.nationalPrefixFormattingRule()
  // 			? format.format().replace(FIRST_GROUP_PATTERN, format.nationalPrefixFormattingRule())
  // 			: format.format()
  // 	)
  withNationalPrefix && format.nationalPrefixFormattingRule() ? format.format().replace(FIRST_GROUP_PATTERN, format.nationalPrefixFormattingRule()) : format.format());

  if (useInternationalFormat) {
    return (0, _applyInternationalSeparatorStyle["default"])(formattedNumber);
  }

  return formattedNumber;
}
//# sourceMappingURL=formatNationalNumberUsingFormat.js.map