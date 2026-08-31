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

/**
 * Composable for the full, unambiguous date and time shown on hover next to a
 * relative timestamp (e.g. "2 days ago"). Formats in the user's dashboard
 * language, so the month name, field order and clock convention read natively.
 *
 * @returns {(time: number) => string} Formatter for a Unix timestamp; returns
 *   an empty string when there is no timestamp.
 *
 * @example
 * const exactTimestamp = useExactTimestamp();
 * exactTimestamp(1770000000); // "Feb 2, 2026, 8:10 AM" / "2 févr. 2026, 08:10"
 */
export function useExactTimestamp() {
  const { resolvedLocale } = useLocale();

  return time => {
    if (!time) return '';

    return formatterFor(resolvedLocale.value).format(fromUnixTime(time));
  };
}
