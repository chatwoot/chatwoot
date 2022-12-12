import { createSummaryValue, isTooLongForDefaultValueSummary } from '../../utils';
import { isDefaultValueBlacklisted } from '../utils/defaultValue';
export function createDefaultValue(defaultValue, type) {
  if (defaultValue != null) {
    const {
      value
    } = defaultValue;

    if (!isDefaultValueBlacklisted(value)) {
      return !isTooLongForDefaultValueSummary(value) ? createSummaryValue(value) : createSummaryValue(type.name, value);
    }
  }

  return null;
}