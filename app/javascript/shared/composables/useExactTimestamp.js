import { fromUnixTime } from 'date-fns';
import { useLocale } from './useLocale';

// Intl formatters are expensive to construct and built for reuse, and the
// formatter runs in the render path of every conversation card, so keep one
// per locale.
const formatters = new Map();

const formatterFor = locale => {
  if (!formatters.has(locale)) {
    formatters.set(
      locale,
      new Intl.DateTimeFormat(locale, {
        dateStyle: 'medium',
        timeStyle: 'short',
      })
    );
  }
  return formatters.get(locale);
};

// Timestamps are interpolated into labels ("last updated {time}"), where a
// locale-formatted date can run in the opposite direction to the surrounding
// text and get reordered into it. Isolating the value keeps it intact, the way
// a `<bdi>` element would for markup.
const FIRST_STRONG_ISOLATE = '⁨';
const POP_DIRECTIONAL_ISOLATE = '⁩';

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

    const timestamp = formatterFor(resolvedLocale.value).format(
      fromUnixTime(time)
    );
    return `${FIRST_STRONG_ISOLATE}${timestamp}${POP_DIRECTIONAL_ISOLATE}`;
  };
}
