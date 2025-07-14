import { normalizeArguments } from './getNumberType.js';
import _isPossibleNumber from '../isPossible.js';
/**
 * Checks if a given phone number is possible.
 * Which means it only checks phone number length
 * and doesn't test any regular expressions.
 *
 * Examples:
 *
 * ```js
 * isPossibleNumber('+78005553535', metadata)
 * isPossibleNumber('8005553535', 'RU', metadata)
 * isPossibleNumber('88005553535', 'RU', metadata)
 * isPossibleNumber({ phone: '8005553535', country: 'RU' }, metadata)
 * ```
 */

export default function isPossibleNumber() {
  var _normalizeArguments = normalizeArguments(arguments),
      input = _normalizeArguments.input,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata; // `parseNumber()` would return `{}` when no phone number could be parsed from the input.


  if (!input.phone && !(options && options.v2)) {
    return false;
  }

  return _isPossibleNumber(input, options, metadata);
}
//# sourceMappingURL=isPossibleNumber.js.map