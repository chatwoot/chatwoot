import { fromUnixTime } from 'date-fns';
import { useLocale } from './useLocale';

// Cache formatters by locale since this runs in the render path.
const formatters = new Map();

const formatterFor = locale => {
  if (!formatters.has(locale)) {
    formatters.set(
      locale,
      new Intl.DateTimeFormat(locale, {
        dateStyle: 'medium',
        timeStyle: 'short',
        // `fa` and `th` would otherwise use the Solar Hijri and Buddhist
        // calendars, dating this differently to the relative time it annotates.
        calendar: 'gregory',
      })
    );
  }
  return formatters.get(locale);
};

// Only used to pick out the localized zone label; `dateStyle`/`timeStyle`
// cannot be combined with `timeZoneName` in a single formatter.
const zoneFormatterFor = locale => {
  const key = `${locale}/zone`;
  if (!formatters.has(key)) {
    formatters.set(
      key,
      new Intl.DateTimeFormat(locale, { timeZoneName: 'short' })
    );
  }
  return formatters.get(key);
};

/**
 * Composable for the full, unambiguous date and time shown on hover next to a
 * relative timestamp (e.g. "2 days ago"). Formats in the user's dashboard
 * language, so the month name, field order and clock convention read natively.
 *
 * @param {Object} [options]
 * @param {boolean} [options.showTimeZone=false] - Append the user's timezone
 *   label in parentheses, e.g. "(GMT+5:30)", for values whose zone would
 *   otherwise be ambiguous.
 * @returns {(time: number) => string} Formatter for a Unix timestamp; returns
 *   an empty string when there is no timestamp.
 *
 * @example
 * const exactTimestamp = useExactTimestamp();
 * exactTimestamp(1770000000); // "Feb 2, 2026, 8:10 AM" / "2 févr. 2026, 08:10"
 */
export function useExactTimestamp({ showTimeZone = false } = {}) {
  const { resolvedLocale } = useLocale();

  return time => {
    if (!time) return '';

    const date = fromUnixTime(time);
    const formatted = formatterFor(resolvedLocale.value).format(date);
    if (!showTimeZone) return formatted;

    const zone = zoneFormatterFor(resolvedLocale.value)
      .formatToParts(date)
      .find(part => part.type === 'timeZoneName').value;
    return `${formatted} (${zone})`;
  };
}
