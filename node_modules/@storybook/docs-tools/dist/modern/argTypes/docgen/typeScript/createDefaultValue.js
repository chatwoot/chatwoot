import { createSummaryValue } from '../../utils';
import { isDefaultValueBlacklisted } from '../utils/defaultValue';
export function createDefaultValue({
  defaultValue
}) {
  if (defaultValue != null) {
    const {
      value
    } = defaultValue;

    if (!isDefaultValueBlacklisted(value)) {
      return createSummaryValue(value);
    }
  }

  return null;
}