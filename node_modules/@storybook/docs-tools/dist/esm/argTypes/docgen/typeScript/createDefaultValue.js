import { createSummaryValue } from '../../utils';
import { isDefaultValueBlacklisted } from '../utils/defaultValue';
export function createDefaultValue(_ref) {
  var defaultValue = _ref.defaultValue;

  if (defaultValue != null) {
    var value = defaultValue.value;

    if (!isDefaultValueBlacklisted(value)) {
      return createSummaryValue(value);
    }
  }

  return null;
}