import _isValidNumber from '../isValid.js';
import { normalizeArguments } from './getNumberType.js'; // Finds out national phone number type (fixed line, mobile, etc)

export default function isValidNumber() {
  var _normalizeArguments = normalizeArguments(arguments),
      input = _normalizeArguments.input,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata; // `parseNumber()` would return `{}` when no phone number could be parsed from the input.


  if (!input.phone) {
    return false;
  }

  return _isValidNumber(input, options, metadata);
}
//# sourceMappingURL=isValidNumber.js.map